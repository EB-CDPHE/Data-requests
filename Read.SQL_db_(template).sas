/**********************************************************************************************
PROGRAM:    Read.[SQL database]
AUTHOR:		Eric Bush
CREATED:	   June 7, 2021
MODIFIED:   060921:  remove macro Shrink from code and add %inc statement to read it instead	
PURPOSE:	   Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

** Libname to access [SQL database name] using ODBC **;
LIBNAME tests144  ODBC  dsn='COVID19' schema=tests;  run;


** Read in the first 50 records to create sample SAS dataset **;
DATA temp_dsn; set libref.SQL_dsn(obs=50); run;    * for building code add (obs=50) ;

/** Review contents of SAS dataset **
 / Look for ID variables that are numeric 
 / Look for date fields that are character variables
 / Document findings below
*/

   PROC contents data=  varnum ;  run;

/*
 / FINDINGS:                                                                 
 / [ID vars] that are a numeric instead of character variable.    
 / (These need to be converted to character prior to running SHRINK macro.     
 / [Date vars] that are a character variable instead of a numeric variable with date format
*/

** Modify SAS dataset per Findings **;
DATA temp_dsn; set temp_dsn(obs=50);     * for building code add (obs=50) ;
* Crfeate a temporary ID character variable for each numeric ID var using the CATS function *;
   ID_char = cats(ID);
   DROP ID;

* Create a temporary date var for each date field that is defined as a character var *;
   Onset_Date = input(onsetdate, yymmdd10.); format Onset_Date yymmdd10.;
   DROP onsetdate;

run;



DATA SeroTests; set tests144.Serology_tests_by_county(obs=50);    * for building code add (obs=50) ;















