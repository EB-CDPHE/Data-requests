/**********************************************************************************************
PROGRAM:  RFI.Montrose_VxCases.sas
AUTHOR:   Eric Bush
CREATED:  December 3, 2021
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=50 ls=150 ;     * Landscape pagesize settings *;
options ps=65 ls=110 ;     * Portrait pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;

   PROC contents data=COVID.CEDRS_view_fix  varnum ;  title1 'COVID.CEDRS_view_fix';  run;


*** Import spreadsheet data from Montrose Vaccine clinic  ***;
***-------------------------------------------------------***;

/*--------------------------------------------------------------------------------------*
 | Email had an attached spreadsheet with following critieria:
 |  * Provider = PEAK FAMILY MEDICINE AND URGENT CARE, 
 |  * Clinic = PEAK FAMILY MEDICINE MONTROSE, 
 |  * From Vaccination Date = 11/12/2021, Through Vaccination Date = 11/13/2021, 
 |  * Funding Source = (ALL FUNDING SOURCES), 
 |  * Vaccine Types = (ALL VACCINES), 
 |  * Refugee Status = (ALL REFUGEE STATUSES)
 |
 | I curated spreadsheet by formatting select columns; deleting admin columns at end
 |  and by deleting report criteria tab.
 *---------------------------------------------------------------------------------------*/

** Montrose.import.sas (auto-generated code from import wizard) **;
   PROC IMPORT OUT= WORK.Montrose 
            DATAFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\20.Montrose VB list\Input data\MontroseClinicList.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="'Patient Details$'"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

** PROC contents of imported spreadsheet data **;
   PROC contents data= Montrose varnum ; title1 'Montrose'; run;


*** Create dataset of Montrose Vaccine Clinic data ***;
***------------------------------------------------***;

** Curate data and create new variables **;
DATA Montrose_fix ; 
   length DOB_LName_FName $ 85  BirthDate $ 10;  
   set Montrose ;

   * Patient_Name field has format Last,First (#) *;
   * parse patient name into last name, then first name, then 'extra' to hold numeric id *;
   Patient_Name_Last  = scan(Patient_Name,1,',', ); *first pass extracts first word using "," delimiter so hyphenated names kept together*;
   First_Name = scan(Patient_Name,2,',',);
   Patient_Name_First = scan(First_Name,1,' ', );  *second pass extracts second word using space delimiter *;
   Patient_Name_Extra = compress(scan(First_Name,2,' ', ),'()'); * compress fx removes () from numeric id values *;
   DROP First_Name;

   * create birthdate var with format YYYY-MM-DD as with CEDRS66.Profiles *;
   BirthDate = cats(put(DOB,yymmdd10.)); format BirthDate $10.;   *catx fx converts numeric date field to char var *;

   * create ID KEY variable based on Birthdate:Last name:First name format *;
   DOB_LName_FName = catx(":", BirthDate, propcase(Patient_Name_Last), propcase(Patient_Name_First) );
   format  DOB_LName_FName  $85. ;

   * calculate age at vaccination *;
   Age_at_Vax = INT(Intck('MONTH', DOB, Vaccination_Date)/12) ;   
   IF month(DOB) = month(Vaccination_Date) then 
      Age_at_Vax =  Age_at_Vax - ( Day(DOB)>Day(Vaccination_Date) );  
run;

** Contents of Montrose Vaccine clinic dataset **;
   PROC contents data= Montrose_fix varnum ; title1 'Montrose_fix'; run;


*** Temp code used in creation of Montrose dataset ***;
***-----------------------------------------------------***;

** Used to check development of birthdate var and ID var **;
/*   PROC freq data=Montrose_fix ;*/
/*      tables birthdate ;*/
/*      tables DOB * birthdate /list;*/
/*      tables Gender  Vaccination_Date  Vaccine_Manufacturer  ;*/
/*run;*/

** Used to check code that parses Patient_Name into first and last name fields **;
/*   PROC print data=Montrose_fix ;*/
/*     id Patient_Name; var   Patient_Name_Last  Patient_Name_First  Patient_Name_Extra  ;*/
/*run;*/

** Used to check final KEY variable that will be used to merge to CEDRS **;
/*   proc sort data=Montrose_fix*/
/*               out=Montrose_sort ;*/
/*      by DOB  Patient_Name_Last  Patient_Name_First ;*/
/*   PROC print data=Montrose_sort ;*/
/*     id DOB_LName_FName; var BirthDate  Patient_Name  ;*/
/*run;*/


***  Link ProfileID and KEY variablbe (DOB:LAST:FIRST) and filter on CEDRS cases  ***;
***-------------------------------------------------------------------------------***;

/*----------------------------------------------------------------------*
 |NOTES:
 |  CEDRS66.Profiles has ProfileID AND DOB, Last Name, First name
 |  DOB, Last Name, First name are the components to the KEY variable
 |  DOB needs to be a character format and not a SAS date var
 |  KEY variable has length $85 and ProfileID has length $15
 |  ==>  Profiles_Key dataset
 *----------------------------------------------------------------------*/

** Access Profiles table from dphe66 **;
LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;     

DATA Profiles; set CEDRS66.Profiles;    
  if Birthdate ne ''   AND   LastName ne ''   AND    FirstName  ne ''   ; 
  keep ProfileID LastName FirstName BirthDate ;
run;

** Check formatting of BirthDate and KEY variable **;
/*   PROC contents data=Profiles  varnum ;  run;    */
/*   proc freq data=profiles; tables birthdate; run;*/

** Create KEY variable using DOB:LAST name:FIRST name **;
   proc sort data=Profiles out=DOB_sort; by BirthDate LastName FirstName ;  run;
DATA Profiles_key;   
   length DOB_LName_FName $ 85   ProfileID $ 15;  
   set DOB_sort(rename=(ProfileID=tmp_ProfileID));  

   DOB_LName_FName = catx(":", Birthdate, propcase(LastName), propcase(FirstName) );
   ProfileID = cats(tmp_ProfileID);
   format  DOB_LName_FName  $85.  ProfileID $15.;
   keep DOB_LName_FName  ProfileID;
run; 

** Check KEY variable attributes **;
/*   PROC contents data=Profiles_key  ; run;*/
/*   PROC print data=Profiles_key;  id DOB_LName_FName;  run;*/


/*---------------------------------------------------------*
 |NOTES:
 |  COVID.CEDRS_view_fix has ProfileID for all cases  
 |  Filter out cases not assigned to a Colorado county
 |  Keep selected variables from CEDRS
 |  ==>  CEDRS dataset
 *---------------------------------------------------------*/

DATA CEDRS; length ProfileID $ 15; set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  ;

   format  ProfileID $15.;
   Keep  ProfileID  EventID  ReportedDate   Age_at_Reported   CollectionDate   
         Outbreak_Associated   Symptomatic  OnsetDate  ;
run;


/*-------------------------------------------------------*
 |NOTES:
 |  SORT Profiles_Key and save as Profiles_sort
 |  SORT CEDRS and save as CEDRS_sort
 |  Merge Profiles_sort and CEDRS_sort on ProfileID.
 |  KEEP only records only from CEDRS 
 |  ==>  CEDRS_key  dataset
 *-------------------------------------------------------*/

   PROC sort  data= Profiles_key  
               out = Profiles_sort; 
      by ProfileID ; 

   PROC sort  data= CEDRS  
               out = CEDRS_sort; 
      by ProfileID ;

DATA CEDRS_key; merge CEDRS_sort(in=c)  Profiles_sort;
   by ProfileID ;

   if c;
run;

** Check format of variables used to merge **;
/*   PROC contents data=CEDRS_sort ; run;*/
/*   PROC contents data=Profiles_sort ; run;*/

** View contents and data from merged dataset **;
/*   PROC print data= COPHS_key; id COPHS_ID; run;*/
/*   PROC contents data=CEDRS_key ;  title1 'CEDRS_key';  run;*/


***  Merge Montrose data with CEDRS using KEY variablbe (DOB:LAST:FIRST) ***;
***______________________________________________________________________***;

/*------------------------------------------------------------------------*
 |NOTES:
 |  SORT Montrose_fix and save as Montrose_DOB
 |  SORT CEDRS_key and save as CEDRS_DOB
 |  Merge Montrose_DOB and CEDRS_DOB on KEY variablbe (DOB:LAST:FIRST).
 |  KEEP records from both Montrose list and CEDRS 
 |  ==>  Montrose_cases  dataset
 *------------------------------------------------------------------------*/

   PROC sort  data= CEDRS_key  
               out = CEDRS_DOB; 
      by DOB_LName_FName ;

   PROC sort  data= Montrose_fix  
               out = Montrose_DOB; 
      by DOB_LName_FName ;

DATA Montrose_cases;  merge Montrose_DOB(in=a)  CEDRS_DOB(in=b) ;
   by DOB_LName_FName ;

   if a=1 and b=1;
run;

** Contents of final dataset:  Montrose_cases  **;
   PROC contents data= Montrose_cases  varnum ; title1 'Montrose_cases'; run;


*** Summary of those vaccianted at Montrose County Vaccination Clinic ***;
***-------------------------------------------------------------------***;

   PROC contents data= Montrose_fix  varnum ; title1 'Montrose_fix'; run;

   PROC format;
         value AgeDec
         0-19 = '0-19 years'
         20-<30 = '20-29 years'
         30-<40 = '30-39 years'
         40-<50 = '40-49 years'
         50-<60 = '50-59 years'
         60-<70 = '60-69 years'
         70-<80 = '70-79 years'
         80-<90 = '80-89 years'
         90-105 = '90-105 years' ;

         value Age4Cat
         0-19 = '0-19 years'
         20-<50 = '20-49 years'
         50-<70 = '50-69 years'
         70-105 = '70-105 years' ;
run;

   PROC freq data= Montrose_fix ;
      tables Vaccination_Date  Gender  Age_at_Vax    Vaccine_Manufacturer ;
      format Age_at_Vax Age4Cat. ;
run;

proc sort data= Montrose_fix   out= Montrose_VxDate; by Vaccination_Date;
   PROC freq data= Montrose_VxDate ;
      tables Gender Age_at_Vax  Vaccine_Manufacturer ;
      by Vaccination_Date;
      format Age_at_Vax Age4Cat. ;
run;

   PROC means data=Montrose_fix  Q1 Median Q3 Mean   maxdec=1;
      class Vaccination_Date;
      var Age_at_Vax ;
run;

   PROC freq data= Montrose_VxDate ;
      tables  Age_at_Vax * Vaccination_Date / chisq ;
      format Age_at_Vax Age4Cat. ;
run;



***  Analyze the n=158 cases that were vaccinated at Montrose clinic on 11/12 or 11/13  ***;
***-------------------------------------------------------------------------------------***;

   PROC contents data= Montrose_cases varnum ;  title1 'Montrose_cases'; run;

** Print listing of cases **;
   PROC print data= Montrose_cases ;
      ID  Patient_Name ;
      var EventID  Gender  Vaccination_Date  Vaccine_Manufacturer  
          Age_at_Reported  OnsetDate  CollectionDate  ReportedDate  ; 
      format Gender $10. ;
run;

** CEDRS case dates **;
/*   PROC freq data= Montrose_cases ;*/
/*      tables ReportedDate  CollectionDate  OnsetDate   ;*/
/*      format ReportedDate  CollectionDate  OnsetDate  monyy. ;*/
/*run;*/
/**/
/*   PROC format;*/
/*         value BeforeAft*/
/*         '01MAR20'd - '31OCT21'd = 'Before 11-1-21'*/
/*         '01NOV21'd - '31DEC21'd = 'After 10-31-21' ;*/
/*run;*/

** Individuals vaccinated in Montrose Nov 12-13 by month reported to CEDRS (prior to 11/1/21) **;
   PROC freq data= Montrose_cases ;
      where ReportedDate < '01NOV21'd;
      tables ReportedDate  ;
      format ReportedDate  monyy. ;
      title2 'ReportedDate before November 2021';
run;
/*   PROC freq data= Montrose_cases ;*/
/*      where ReportedDate > '31OCT21'd;*/
/*      tables ReportedDate * CollectionDate * OnsetDate / list  ;*/
/*      format ReportedDate  CollectionDate  OnsetDate  WeekU5. ;*/
/*      title2 'ReportedDate in November 2021';*/
/*run;*/


** Montrose Vaccinatee's reported as CEDRS case after 11/1/21 **;
   proc sort data=Montrose_cases
               out=Montrose_cases_VXsort ;
      by CollectionDate OnsetDate;
run;
   PROC print data= Montrose_cases_VXsort n;
      where ReportedDate > '31OCT21'd;
      id  Patient_Name ; var  Vaccination_Date  OnsetDate  CollectionDate  ReportedDate  Symptomatic ProfileID  EventID;
      format ProfileID $10. ;
      title2 'ReportedDate during November 2021';
run;


** Characteristics of Montrose Vaccinatee's recently reported as cases **;
   PROC freq data= Montrose_cases ;
      where ReportedDate > '31OCT21'd;
      tables Vaccination_Date  Gender  Age_at_Vax   Vaccine_Manufacturer    ;
      format Age_at_Vax Age4Cat. Gender $10. ;
run;
