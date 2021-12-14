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
 | --> delete Age group and Gender values and rename Group variable to County.
 *______________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA Pat_temp; set Just146.Patient(rename=
                 (ProfileID=tmp_ProfileID   EventID=tmp_EventID
                  DOB=tmp_DOB  specimen_collection_date=tmp_specimen_collection_date )); 

* Convert temporary numeric ID variable character ID var using the CATS function *;
   ProfileID = cats(tmp_ProfileID);
   EventID = cats(tmp_EventID);

* Convert temporary character var for each date field to a date var *;
   DOB = input(tmp_DOB, yymmdd10.);  format tmp_DOB yymmdd10.;
   specimen_collection_date = input(tmp_specimen_collection_date, yymmdd10.);  format tmp_specimen_collection_date yymmdd10.;

   KEEP  opened_date  case_type  age  case_name  county_display  dob  event_id  first_name  full_name
         gender  hospitalized  household_residents  last_name  name Profile_ID  specimen_collection_date
         occupation  other_hcw  work_while_symptoms  occupation_specify  
         occupation_other  occupation_other_2  occupation_other_3  occupation_other_4
         add_another_occupation_1  add_another_occupation_2  occupation_2  occupation_3  
         occupation_specify_2  occupation_specify_3  ;

run;
PROC contents data=Pat_temp  varnum ;  run;    


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Pat_temp)

*  --> output dsn will be "COPHS_temp_"   (NOTE: underscore appended to end of dsn) ;


** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COVID.County_Population ; set Pop_temp_ ;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=COVID.County_Population varnum; run;


PROC SQL;
   create table Patients

SELECT TOP (1000) [id]
      ,[opened_date]
      ,[case_type]
      ,[age]
      ,[case_name]
      ,[county_display]
      ,[dob]
      ,[event_id]
      ,[first_name]
      ,[full_name]
      ,[gender]
      ,[hospitalized]
