/**********************************************************************************************
PROGRAM:  RFI.Boulder_HCW.sas
AUTHOR:   Eric Bush
CREATED:  December 13, 2021
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

   PROC contents data=Patient_Occupation varnum;  title1 'Patient_Occupation';  run;


*** Check data from Dr Justina Patient data table ***;
***-----------------------------------------------***;

* Case Classification *;
   PROC freq data= Patient_Occupation  ;
      tables cdphe_case_classification ;
      title2 'dphe146 DrJustina-Prod';
run;
/*--------------------------------------------------------*
 FINDINGS:
 | Case classification = confirmed for >90% of records.
 | N=689,759 confirmed cases.
 *--------------------------------------------------------*/

* Healthcare Worker indicator *;
   PROC freq data= Patient_Occupation  ;
      where lowcase(cdphe_case_classification) = 'confirmed';
      tables HCW / missing missprint ;
      label HCW = 'HealthCare Worker';
      title2 'dphe146 DrJustina-Prod';
      title3 'Case classification = CONFIRMED';
run;
/*----------------------------------------------*
 FINDINGS:
 |  HCW=missing for >98% of confirmed cases.
 *----------------------------------------------*/

* Using Occupation variables to impute for HCW=missing *;
   PROC freq data= Patient_Occupation ;
      where lowcase(cdphe_case_classification) = 'confirmed';
      tables Occupation  Occupation_2   Occupation_3  Occupation_4  / missing missprint ;
run;
/*---------------------------------------------------------------------------------------------*
 FINDINGS:
 |  Occupations have format of general, specific.
 |  The majority of the general occupation titles have specific descriptor of "healthcare"
 |  There is also a general occupation title of "healthcare".
 *---------------------------------------------------------------------------------------------*/

* specimen_collection_date *;
   PROC means data= Patient_Occupation  n nmiss;
      where lowcase(cdphe_case_classification) = 'confirmed';
      var specimen_collection_date;
run;
/*-----------------------------------------------------------------------*
 FINDINGS:
 |  About half of confirmed cases are missing specimen collection date.
 *-----------------------------------------------------------------------*/


title;  options pageno=1;


*** Filter and curate DrJustina dataset ***;
***-------------------------------------***;

   DATA Patient_cases;  set Patient_Occupation;
      where lowcase(cdphe_case_classification) = 'confirmed';

* Backfill missing HCW data *;
   if HCW='' then DO;
           if index(Occupation,   'healthcare')>0 then HCW='yes';
      else if index(Occupation_2, 'healthcare')>0 then HCW='yes';
      else if index(Occupation_3, 'healthcare')>0 then HCW='yes';
      else if index(Occupation_4, 'healthcare')>0 then HCW='yes';
     else HCW='no';
   END;

   RENAME Profile_ID=ProfileID
          Event_ID= EventID;

   KEEP  Profile_ID  Event_ID  HCW   specimen_collection_date  ;
run;

   PROC contents data=Patient_cases   ;  title1 'Patient_cases';  run;


*** Merge DrJustina data with CEDRS ***;
***---------------------------------***;

/*   PROC contents data=COVID.CEDRS_view_fix   ;  title1 'COVID.CEDRS_view_fix';  run;*/
   PROC sort data=COVID.CEDRS_view_fix(KEEP=ProfileID EventID CaseStatus ReportedDate CollectionDate)
               out=CEDRS_sort;
      by ProfileID  EventID ;
run;
/*   PROC contents data=CEDRS_sort   ;  title1 'CEDRS_sort';  run;*/

   PROC sort data=Patient_cases
               out=DrJ_sort;
      by ProfileID  EventID ;
run;

DATA CEDRS_HCW; 
   merge CEDRS_sort(in=C)  DrJ_sort(in=J) ;
      by ProfileID  EventID ;
      if J;

      * impute missing date values *;
      if specimen_collection_date=. and CollectionDate ne . then specimen_collection_date = CollectionDate;
      else if CollectionDate=. and specimen_collection_date ne . then CollectionDate = specimen_collection_date;

      if ReportedDate=. and specimen_collection_date ne . then ReportedDate = specimen_collection_date;
run;
   PROC contents data=CEDRS_HCW   ;  title1 'CEDRS_HCW';  run;


*** Compare Date vars ***;
***-------------------***;

   PROC means data= CEDRS_HCW  n nmiss;
      var  ReportedDate  CollectionDate  specimen_collection_date;
run;

   PROC freq data= CEDRS_HCW;
/*      tables  CollectionDate * specimen_collection_date / list missing missprint;*/
      tables ReportedDate * CollectionDate * specimen_collection_date / list missing missprint;
      format ReportedDate  CollectionDate  specimen_collection_date monyy. ;
run;



*** Fix Patient dataset ***;
***---------------------***;

libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;
DATA DASH.HCW ; set COVID.Patient ;

run;




proc freq data= HCW_temp;
   tables specimen_collection_date;
   format specimen_collection_date monyy.;
run;

proc freq data= HCW_temp;
   where year(specimen_collection_date)=2021;
   tables specimen_collection_date  * HCW ;
   format specimen_collection_date monyy.;
run;


*** Create dataset for responding to data request ***;
***-----------------------------------------------***;
DATA HCW ; set ;



*** Proportion of cases that were HealthCare Workers ***;
***--------------------------------------------------***;


*** Explore variables ***;
***-------------------***;

** Gender values **;
   PROC freq data= Patient order=freq;
      tables Gender;
run;
/*-------------------------------------------*
 |FINDINGS:
 | n=764,450 (97.94%) are male or female
 | n=15,857 (2.03%) are unknown
 | n=215 are other
 *-------------------------------------------*/


** Hospitalized values **;
   PROC freq data= Patient  order=freq;
      tables hospitalized ;
run;
/*---------------------------------------------------------------------------------------------*
 |FINDINGS:
 | Meant to be a YES/NO question, there are 10 different responses
 | Curated variable in Access program to compress and change to upcase
 | Now there are 3 character responses (YES/NO/UNKNOWN) and 3 numeric response (119/120/121)
 *---------------------------------------------------------------------------------------------*/


** symptomatic, stub, and variant_test_type values **;
   PROC freq data= Patient  order=freq;
      tables symptomatic stub variant_test_type;
run;
/*--------------------*
 |FINDINGS:
 | All looks good. 
 *--------------------*/


*** Explore Occupational variables ***;
***--------------------------------***;
   PROC print data= Patient  ;
      id Profile_ID ;
      var HCW   HCW_type  Other_HCW   ;* 
         Occupation          Occupation_2          Occupation_3          Occupation_4
         Occupation_other    Occupation_other_2    Occupation_other_3    Occupation_other_4
         Occupation_specify  Occupation_specify_2  Occupation_specify_3  Occupation_specify_4  ;
run;

   PROC format;
      value $AnyDataFmt
         ' '='Missing data'
         other='Has data' ;       
run;

   PROC freq data= Patient  ;
      tables HCW ;
run;


** Describe HCW and Occupation fields **;
   PROC freq data= COVID.Patient;
/*      tables HCW  / missing missprint ;*/
      tables Occupation  Occupation_2   Occupation_3  Occupation_4  / missing missprint ;
run;



***  Re-assign HCW_type=other to more specific categories  ***;
***--------------------------------------------------------***;

   PROC freq data= Patient  order=freq;
      where HCW='yes';
      tables HCW_type / missing  missprint;
      title1 'HCW_type';
run;

** Chk 1: Other responses **;
   PROC freq data= Patient  ;
      where HCW='yes'  AND  HCW_type='other' ;
      tables Other_HCW /   missing  missprint ;
      title1 'Other_HCW';
run;

** Chk 1.1 - ACCOUNT  **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'ACCOUNT' )>0;
      tables Other_HCW ;
      title1 'ACCOUNT';
run;

** Chk 1.2 - ADMIN  **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'ADMIN' )>0;
      tables Other_HCW ;
      title1 'ADMIN';
run;

** Chk 1.3 - RECEPTION  **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'RECEPTION' )>0;
      tables Other_HCW ;
      title1 'RECEPTION';
run;

** Chk 1.4 - ANESTHESIOLOGIST **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'ANESTHESIOLOGIST' )>0;
      tables Other_HCW ;
      title1 'ANESTHESIOLOGIST';
run;

** Chk 1.5 - ANESTH_ **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'ANESTH' )>0 AND 
            index(upcase(Other_HCW), 'ANESTHESIOLOGIST' )=0;
      tables Other_HCW ;
      title1 'ANESTH_';
run;

** Chk 1.6 - AID **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'AID' )>0 ; 
      tables Other_HCW ;
      title1 'AID';
run;
/* Too non-specific */

** Chk 1.7 - CARE_ **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'CARE' )>0  AND 
            (index(upcase(Other_HCW), 'PROVID' )>0  OR  index(upcase(Other_HCW), 'GIVE' )>0  OR  index(upcase(Other_HCW), 'TAKE' )>0 ) ; 
      tables Other_HCW ;
      title1 'CARE_';
run;
/* Move after receptionist and after CNA */

** Chk 1.8 - NURSE **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'NURSE' )>0  ; 
      tables Other_HCW ;
      title1 'NURSE';
run;

** Chk 1.9 - CNA **;
   proc freq data=patient;
      where HCW_type='other'  AND  index(upcase(Other_HCW), 'CNA' )>0  ; 
      tables Other_HCW ;
      title1 'CNA';
run;

** Chk 1.10 - EMT **;
   proc freq data=patient;
      where HCW_type='other'  AND  ( index(upcase(Other_HCW), 'EMT' )>0  OR  index(upcase(Other_HCW), 'AMBULANCE' )>0 )  ; 
      tables Other_HCW ;
      title1 'EMT';
run;


** Fix **;
**-------***;
DATA Patient_fix; set Patient;

        if index(upcase(Other_HCW), 'ADMIN' )>0 then do; HCW_type='other: ADMIN';  Other_HCW='MOVED'; end;
   ELSE if index(upcase(Other_HCW), 'ACCOUNT' )>0 then do; HCW_type='other: ADMIN';  Other_HCW='MOVED'; end;
   ELSE if index(upcase(Other_HCW), 'RECEPTION' )>0 then do; HCW_type='other: ADMIN';  Other_HCW='MOVED'; end;
   ELSE if index(upcase(Other_HCW), 'ANESTHESIOLOGIST' )>0 then do; HCW_type='physician';  Other_HCW='MOVED'; end;
   ELSE if index(upcase(Other_HCW), 'ANESTH' )>0 then do; HCW_type='nurse';  Other_HCW='MOVED'; end;
   ELSE if index(upcase(Other_HCW), 'NURSE' )>0 then do; HCW_type='nurse';  Other_HCW='MOVED'; end;
   ELSE if index(upcase(Other_HCW), 'CNA' )>0 then do; HCW_type='other: CNA';  Other_HCW='MOVED'; end;
   ELSE if index(upcase(Other_HCW), 'CARE' )>0 AND 
         ( index(upcase(Other_HCW), 'PROVID' )>0  OR  index(upcase(Other_HCW), 'GIVE' )>0  OR  index(upcase(Other_HCW), 'TAKE' )>0 ) 
       then do; HCW_type='other: CAREGIVER';  Other_HCW='MOVED'; end;
   ELSE if index(upcase(Other_HCW), 'EMT' )>0 then do; HCW_type='other: EMT';  Other_HCW='MOVED'; end;



run;

/*   PROC freq data= Patient_fix  ;*/
/*      where HCW='yes'  AND  HCW_type='other' ;*/
/*      tables Other_HCW /   missing  missprint ;*/
/*run;*/


*** Filter data  ***;
***------------***;

DATA CEDRS_filtered;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND
   (  month(ReportedDate)=9; 

   Keep  ProfileID  EventID  CountyAssigned   ReportedDate  Gender  Age_at_Reported   CollectionDate   
         Symptomatic  OnsetDate  outcome  casestatus  hospitalized  breakthrough    Vax_UTD  ;
run;

   PROC contents data=CEDRS_filtered  varnum ;  title1 'CEDRS_filtered';  run;
