/**********************************************************************************************
PROGRAM:    Read.CEDRS_view
AUTHOR:		Eric Bush
CREATED:	   June 7, 2021
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


** 2. Read in the first 50 records to create sample SAS dataset **;
DATA SQL_dsn; set dbo144.COVID19(obs=50); run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=SQL_dsn  varnum ;  run;    

/* Look for ID variables that are numeric */
/* Look for date fields that are character variables */
/* Document findings below */

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    [ID vars] that are a numeric instead of character variable.    
 |    (These need to be converted to character prior to running SHRINK macro.     
 |    [Date vars] that are a character variable instead of a numeric variable with date format
 *________________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA SQL_dsn_temp; set SQL_dsn(rename=(ID=tmp_ID onsetdate=tmp_onsetdate )); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ID = cats(tmp_ID);

* Convert temporary character var for each date field to a date var *;
   OnsetDate = input(tmp_onsetdate, yymmdd10.); format OnsetDate yymmdd10.;

   DROP tmp_: ;
run;


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(SQL_dsn_temp)


** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COVID.SQL_dsn ; set SQL_dsn_temp_ ;
run;


   PROC contents data=COVID.SQL_dsn varnum; run;













