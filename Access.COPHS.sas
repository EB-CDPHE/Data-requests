/**********************************************************************************************
PROGRAM:    Access.COPHS
AUTHOR:		Eric Bush
CREATED:	   June 22, 2021
MODIFIED:   071921: Update per other RFI patterns for SAS programs. Move access and check programs to parent directory.	
PURPOSE:	   Connect to dphe144 "hospital" and create associated SAS dataset.
            The main changes are to convert date fields to true SAS date variables AND
            to shrink character variables to smallest possible size.
INPUT:		Hosp144.COPHS
OUTPUT:		        COPHS_read
***********************************************************************************************/

/*________________________________________________________________________________________________________*
 | What this program does:
 | 1. Define library to access COPHS database on Hosp144 server using ODBC
 | 2. Create temporary SAS dataset from COPHS data table in the Hospital schema and report findings
 | 3. Use Proc Freq (first time accessing data table) to learn format of date variables
 | 4. Modify SAS dataset per Findings
 |      a) No ID vars that I can recognize. Perhaps MR_Number but it is character variable.
 |      b) Convert temporary character var for each date field to a date var
 | 5. Shrink character variables in data set to shortest possible length (based on longest value)
 | 6. Define library to store permanent SAS dataset
 | 7. Rename "shrunken" SAS dataset (by removing underscore added by macro)
 | 8. PROC contents of final dataset
 *________________________________________________________________________________________________________*/

** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME Hosp144    ODBC  dsn='COVID19' schema=hospital;  run;
 

** 2. Read in the first 50 records to create sample SAS dataset **;
DATA COPHS; set Hosp144.COPHS; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=COPHS  varnum ;  run;    

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    No ID vars that I can recognize. Perhaps MR_Number but it is character variable.    
 |    Several date vars that are a character variables are dumped into PROC freq to determine format |    
 *________________________________________________________________________________________________*/


** 3. determine format of dates in the char vars **;
/*   PROC freq data=COPHS ;*/
/*      tables Hospital_Admission_Date___MM_DD_*/
/*             ICU_Admission_Date___MM_DD_YYYY_*/
/*             DOB__MM_DD_YYYY_*/
/*             Positive_COVID_19_Test_Date*/
/*             Discharge_Transfer__Death_Date__*/
/*             Last_Day_in_ICU_During_Admission  ;  * date fields;*/
/*run;*/

** 3.a) explore obs with bad date value **;
/*   proc print data= COPHS;*/
/*   where MR_Number='228438';*/
/*   var MR_Number Discharge_Transfer__Death_Date__ ;*/
/*   run;*/
* --> value will get set to missing *;


** 4. Modify SAS dataset per Findings **;
DATA COPHS_temp;  set COPHS; 
 
* Convert temporary character var for each date field to a date var *;
   Hosp_Admission    = input(Hospital_Admission_Date___MM_DD_, yymmdd10.); format Hosp_Admission mmddyy10.;
   ICU_Admission     = input(ICU_Admission_Date___MM_DD_YYYY_, yymmdd10.); format ICU_Admission mmddyy10.;
   DOB               = input(DOB__MM_DD_YYYY_, yymmdd10.);                 format DOB mmddyy10.;
   Positive_Test     = input(Positive_COVID_19_Test_Date, yymmdd10.);      format Positive_Test mmddyy10.;
   Date_left_facility= input(Discharge_Transfer__Death_Date__, yymmdd10.); format Date_left_facility mmddyy10.;
   Last_Day_in_ICU   = input(Last_Day_in_ICU_During_Admission, yymmdd10.); format Last_Day_in_ICU mmddyy10.;

   Label
      Hosp_Admission = 'Hospital Admission date'
      ICU_Admission  = 'ICU Admission date'
      DOB            = 'Date of Birth'
      Positive_Test  = 'Positive COVID19 test date'
      Date_left_facility = 'Date of Discharge, Transfer, or Death'
      Last_Day_in_ICU = 'Last day in ICU during Admission'   ;

   DROP 
      Hospital_Admission_Date___MM_DD_ 
      ICU_Admission_Date___MM_DD_YYYY_
      DOB__MM_DD_YYYY_
      Positive_COVID_19_Test_Date
      Discharge_Transfer__Death_Date__
      Last_Day_in_ICU_During_Admission  ;
run;


** 5. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(COPHS_temp)

*  --> output dsn will be "COPHS_temp_"   (NOTE: underscore appended to end of dsn) ;


** 6. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 7. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COPHS_read ; set COPHS_temp_ ;
run;


**  8. PROC contents of final dataset  **;
   PROC contents data= COPHS_read varnum; run;


