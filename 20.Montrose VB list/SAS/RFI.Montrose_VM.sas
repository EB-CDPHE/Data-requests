/**********************************************************************************************
PROGRAM:  RFI.Montrose_VB.sas
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



*** Import spreadsheet data  ***;
***--------------------------***;

/*
 | Email attached spreadsheet with following critieria:
   * Provider = PEAK FAMILY MEDICINE AND URGENT CARE, 
   * Clinic = PEAK FAMILY MEDICINE MONTROSE, 
   * From Vaccination Date = 11/12/2021, Through Vaccination Date = 11/13/2021, 
   * Funding Source = (ALL FUNDING SOURCES), 
   * Vaccine Types = (ALL VACCINES), 
   * Refugee Status = (ALL REFUGEE STATUSES)

 | I curated spreadsheet by formatting select columns; deleting admin columns at end
   and by deleting report criteria tab.
 */

** Import.SAS code **

** PROC contents of imported spreadsheet data **;
   PROC contents data=  Montrose  varnum ; title1 'Montrose'; run;

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

   * create ID KEY variable based on Birthdate:Last name:First name format*;
   DOB_LName_FName = catx(":", BirthDate, propcase(Patient_Name_Last), propcase(Patient_Name_First) );
   format  DOB_LName_FName  $85. ;
run;


/*   PROC contents data= Montrose_fix varnum ; title1 'Montrose_fix'; run;*/

** use to check development of birthdate var and ID var **;
/*   PROC freq data=Montrose_fix ;*/
/*      tables birthdate ;*/
/*      tables DOB * birthdate /list;*/
/*      tables Gender  Vaccination_Date  Vaccine_Manufacturer  ;*/
run;

** Use to check code that parses Patient_Name into first and last name fields **;
/*   PROC print data=Montrose_fix ;*/
/*     id Patient_Name; var   Patient_Name_Last  Patient_Name_First  Patient_Name_Extra  ;*/
/*run;*/


   proc sort data=Montrose_fix
               out=Montrose_sort ;
      by DOB  Patient_Name_Last  Patient_Name_First ;
run;

** Use to check final ID variable that will be used to merge to CEDRS **;
   PROC print data=Montrose_sort ;
     id DOB_LName_FName; var BirthDate  Patient_Name  ;
run;




** Create link between ProfileID and Name and DOB **;

LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;     

DATA Profiles; set CEDRS66.Profiles;    
  if Birthdate ne ''   AND   LastName ne ''   AND    FirstName  ne ''   ; 
  keep ProfileID LastName FirstName BirthDate ;
run;
   PROC contents data=Profiles  varnum ;  run;    
proc freq data=profiles; tables birthdate; run;

   proc sort data=Profiles out=DOB_sort; by BirthDate LastName FirstName ;  run;
DATA Profiles_key;   
   length DOB_LName_FName $ 85   ProfileID $ 15;  
   set DOB_sort(rename=(ProfileID=tmp_ProfileID));  

   DOB_LName_FName = catx(":", Birthdate, propcase(LastName), propcase(FirstName) );
   ProfileID = cats(tmp_ProfileID);
   format  DOB_LName_FName  $85.  ProfileID $15.;
   keep DOB_LName_FName  ProfileID;
run; 


   PROC contents data=Profiles_key  ; run;
   PROC print data=Profiles_key;  id DOB_LName_FName;  run;



***  CEDRS66.Profiles has ProfileID and DOB and Name   ***;
***  COVID.CEDRS_view_fix has ProfileID for all cases  ***;
***  Merge the two on ProfileID and keep cases only.   ***;
***____________________________________________________***;


DATA CEDRS; length ProfileID $ 15; set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  ;

   format  ProfileID $15.;
   Keep  ProfileID  EventID  CountyAssigned   ReportedDate   Age_at_Reported   CollectionDate   
         LiveInInstitution   Homeless   Outbreak_Associated   Symptomatic  OnsetDate  ;
run;


   PROC sort  data= CEDRS(keep=ProfileID)  
               out = CEDRS_sort; 
      by ProfileID ;

   PROC sort  data= Profiles_key  
               out = Profiles_sort; 
      by ProfileID ;

DATA CEDRS_key; merge CEDRS_sort(in=c)  Profiles_sort;
   by ProfileID ;

   if c;
run;


   PROC contents data=CEDRS_sort ; run;
   PROC contents data=Profiles_sort ; run;

/*   PROC print data= COPHS_key; id COPHS_ID; run;*/



***  Merge Montrose data with CEDRS using DOB_LName_FName key ***;
***___________________________________________________________***;


   PROC sort  data= CEDRS_key  
               out = CEDRS_DOB; 
      by DOB_LName_FName ;

   PROC sort  data= Montrose_sort  
               out = Montrose_DOB; 
      by DOB_LName_FName ;

DATA Montrose_cases;  merge Montrose_DOB(in=a)  CEDRS_DOB(in=b) ;
   by DOB_LName_FName ;

   if a=1 and b=1;
run;

   PROC contents data= Montrose_cases  varnum ; title1 'Montrose_cases'; run;


***  Analyze the n=158 cases that were vaccinated at Montrose clinic on 11/12 or 11/13  ***;
***-------------------------------------------------------------------------------------***;

   PROC print data=  ;
      ID  Patient_Name ;
      var Gender Vaccination_Date  ;
run;
