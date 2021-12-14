/**********************************************************************************************
PROGRAM:    Access.DrJustina.sas
AUTHOR:		Eric Bush
CREATED:	   December 13, 2021
MODIFIED:   
PURPOSE:	   Connect to dphe146 "DrJustina_prod" and create associated SAS dataset.
INPUT:		dbo146.populations
OUTPUT:		COVID.County_Population
***********************************************************************************************/

/*---------------------------------------------------------------------------------------------------*
 | What this program does:
 | 1. Define library to access COVID19 database on dbo144 server using ODBC
 | 2. Create temporary SAS dataset from Populations SQL table in the dbo schema. Review findings.
 | 3. Modify SAS dataset per Findings
 |    a) Delete Group=Age
 |    b) Delete Group=Gender
 |    c) The only obs that remain are county name so rename Group variable to County
 | 4. Shrink character variables in data set to shortest possible length (based on longest value)
 | 5. Define library to store permanent SAS dataset
 | 6. Rename "shrunken" SAS dataset
 | 7. PROC contents of final dataset
 *---------------------------------------------------------------------------------------------------*/

*** County Population data ***;
***------------------------***;

** 1. Libname to access Populations database on dbo144 server using ODBC **;
LIBNAME Just146  ODBC  dsn='DrJustina' schema=dbo;  run;


** 2. Review contents of SAS dataset **;
PROC contents data=Just146.Patient  varnum ;  run;    

/*______________________________________________________________________________________________*
 |FINDINGS:
 | There are 965 variables!
 | So use Keep= in SET statement to improve efficiency.
 *______________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA Pat_temp; set Just146.Patient(rename=(DOB=tmp_DOB  specimen_collection_date=tmp_spec_coll_date  hospitalized = tmp_hospitalized )  
                                    KEEP=Profile_ID  Event_id  stub  hospitalized  gender   dob  first_name  full_name
         HCW  HCW_Type  other_hcw  job_address_information  job_description_occupation
         Occupation          Occupation_2          Occupation_3          Occupation_4
         Occupation_other    Occupation_other_2    Occupation_other_3    Occupation_other_4
         Occupation_specify  Occupation_specify_2  Occupation_specify_3  Occupation_specify_4  
         Work_while_symptoms Work_while_symptoms_2 Work_while_symptoms_3 Work_while_symptoms_4  
         Household_residents  Housing  last_name  name  specimen_collection_date  symptomatic
         variant_test_type ); 

* Convert case of response values to be more consistent *;
   Hospitalized = upcase(compress(tmp_hospitalized));

* Convert temporary character var for each date field to a date var *;
                        DOB  = input(tmp_dob, yymmdd10.);            format DOB mmddyy10.;
    specimen_collection_date = input(tmp_spec_coll_date, yymmdd10.); format specimen_collection_date mmddyy10.;

    DROP tmp_: ;
run;

PROC contents data=Pat_temp  varnum ;  run;    


** 4. determine format of dates that are character variables **;
   PROC freq data=Pat_temp ;
      tables tmp_dob;
      format tmp_dob  specimen_collection_date  $12.;
run;
/*------------------------------------------*
 |FINDINGS:
 | n=19 obs with tmp_dob < '1900-01-01'
 | n=13 obs with tmp_dob = '1900-01-01'
 | n=38 obs with tmp_dob > '2022-06-01'
 | n=6835 obs with tmp_dob = missing
 *------------------------------------------*/

   PROC freq data=Pat_temp ;
      tables specimen_collection_date ;
      format tmp_dob  specimen_collection_date  $12.;
run;
/*------------------------------------------------------------*
 |FINDINGS:
 | n=121 obs with specimen_collection_date < '2020-01-01'
 | n= 40 obs with specimen_collection_date > '2021-12-13'
 | n= 415076 with specimen_collection_date = missing.
 *------------------------------------------------------------*/


** review four obs that triggered error messages **;
   PROC print data= Pat_temp;
      where  event_id in ('1122519');
      var Event_ID tmp_dob  DOB;
/*      format tmp_dob $12.;*/
run;





** 5. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Pat_temp)

*  --> output dsn will be "COPHS_temp_"   (NOTE: underscore appended to end of dsn) ;


** 6. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 7. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Patient ; set Pat_temp_ ;
run;


**  8. PROC contents of final dataset  **;
   PROC contents data=Patient varnum; run;

