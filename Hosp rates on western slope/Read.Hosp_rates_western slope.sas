/**********************************************************************************************
PROGRAM:    Read.Hosp_rate_western slope
AUTHOR:		Eric Bush
CREATED:	   June 22, 2021
MODIFIED:   060921:  remove macro Shrink from code and add %inc statement to read it instead	
PURPOSE:	   Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

/*________________________________________________________________________________________________________*
 | Required user input for this code to work:
 | *** FIRST CHANGE PROGRAM NAME IN HEADER AND SAVE FILE WITH THIS NEW NAME. ***
 |    1. Complete libname stm with Libref, dsn, and schema.  See CEDRS.Libnames.sas
 |    2. Insert libref and dsn into Data step. This data step will be run twice.
 |       a. The first time, use obs=50 option. Review proc contents output.
 |       b. Record findings. See expected findings below.
 |    3. Modify second Data step per findings. Creates a temporary data set.
 |    4. Shrink character variables in data set to shortest possible lenght (based on longest value).
 |       ** Get Macro.Shrink.sas program from GitHub repository "SAS-code-library".
 |       ** NOTE: macro saves to new dataset by adding "_" to end of dataset name provided by user.
 |    5. Create libname for folder to store permanent SAS dataset (if desired). e.g on J: drive.
 |    6. Rename "shrunken" SAS dataset by removing underscore added by macro.
 *________________________________________________________________________________________________________*/

** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";
LIBNAME Hosp144    ODBC  dsn='COVID19' schema=hospital;  run;


** 2. Read in the first 50 records to create sample SAS dataset **;
DATA COPHS; set Hosp144.COPHS(obs=50); run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=COPHS  varnum ;  run;    

/* Look for ID variables that are numeric */
/* Look for date fields that are character variables */
/* Document findings below */

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    No ID vars that I can recognize. Perhaps MR_Number but it is character variable.    
 |    Several date vars that are a character variable:
 |    
 *________________________________________________________________________________________________*/

** determine format of dates in the char vars **;
   PROC freq data=COPHS ;
      tables Hospital_Admission_Date___MM_DD_
            ICU_Admission_Date___MM_DD_YYYY_
            DOB__MM_DD_YYYY_
            Positive_COVID_19_Test_Date
            Last_Day_in_ICU_During_Admission  ;  * date fields;
run;


** 3. Modify SAS dataset per Findings **;
DATA COPHS_temp; set COPHS; 
 
* Convert temporary character var for each date field to a date var *;
   Hosp_Admission = input(Hospital_Admission_Date___MM_DD_, yymmdd10.); format Hosp_Admission yymmdd10.;
   ICU_Admission = input(ICU_Admission_Date___MM_DD_YYYY_, yymmdd10.); format ICU_Admission yymmdd10.;
   DOB = input(DOB__MM_DD_YYYY_, yymmdd10.); format DOB yymmdd10.;
   Positive_Test = input(Positive_COVID_19_Test_Date, yymmdd10.); format Positive_Test yymmdd10.;
   Last_Day_in_ICU = input(Last_Day_in_ICU_During_Admission, yymmdd10.); format Last_Day_in_ICU yymmdd10.;

   Label
      Hosp_Admission = 'Hospital Admission date'
      ICU_Admission = 'ICU Admission date'
      DOB = 'Date of Birth'
      Positive_Test = 'Positive COVID19 test date'
      Last_Day_in_ICU = 'Last day in ICU during Admission'   ;

   DROP 
      Hospital_Admission_Date___MM_DD_ 
      ICU_Admission_Date___MM_DD_YYYY_
      DOB__MM_DD_YYYY_
      Positive_COVID_19_Test_Date
      Last_Day_in_ICU_During_Admission  ;

run;


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(COPHS_temp)


** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COVID.COPHS ; set COPHS_temp_ ;
run;


   PROC contents data=COVID.COPHS varnum; run;













