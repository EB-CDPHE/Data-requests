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

   PROC contents data=COVID.Patient  varnum ;  title1 'COVID.Patient';  run;


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
