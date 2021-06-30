/**********************************************************************************************
PROGRAM:    Read.[CEDRS_SQL_table]
AUTHOR:		Eric Bush
CREATED:	   June 7, 2021
MODIFIED:   060921:  remove macro Shrink from code and add %inc statement to read it instead	
PURPOSE:	   Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

/*_____________________________________________________________________________________________________________________*
 | Required user input for this code to work:
 | *** FIRST CHANGE PROGRAM NAME IN HEADER AND SAVE FILE WITH THIS NEW NAME. ***
 |    1. Complete libname stm with Libref, dsn, and schema.  
 |       a. See CEDRS.Libnames.sas for list of libnames and schemas.
 |       b. Use Explorere window to see what data tables exist in the schema pointed to by Libname stm.
 |    2. Insert libref and dsn into Data step. This data step will be run twice.
 |       a. The first time, use obs=50 option. Review proc contents output.
 |       b. Record findings. See expected findings below.
 |    3. Modify second Data step per findings. Creates a temporary data set.
 |    4. Shrink character variables in data set to shortest possible lenght (based on longest value).
 |       ** Get Macro.Shrink.sas program from GitHub repository "SAS-code-library".
 |       ** NOTE: macro saves to new dataset by adding "_" to end of dataset name provided by user.
 |    5. Create libname for folder to store permanent SAS dataset (if desired). e.g on J: drive.
 |    6. Rename "shrunken" SAS dataset by removing underscore added by macro.
 *______________________________________________________________________________________________________________________*/

** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         * contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";


   %Let SQL_dsn = CEDRS_view;              * <-- put name of selected data table from schema here ;


** 2. Read in the first 50 records to create sample SAS dataset **;
DATA &SQL_dsn; set dbo144.&SQL_dsn (obs=50); run;                * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=&SQL_dsn  varnum ;  run;    

/* Look for ID variables that are numeric.  These should be transformed to character variables. */
/* Look for date fields that are character variables.  These should be transformed to date variables. */
/* Look for variable names that are lengthy or have odd characters.  These should be renamed. */
/* Look for character variables that have length and format of $255. These should be shrunk to smallest length.  */
/* Document findings below */

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    [ID vars] that are a numeric instead of character variable.    
 |    (These need to be converted to character prior to running SHRINK macro.     
 |    [Date vars] that are a character variable instead of a numeric variable with date format
 |    Character vars have length and format of $255. 
 *________________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA &SQL_dsn._temp; set &SQL_dsn(rename=(ID=tmp_ID onsetdate=tmp_onsetdate ));     * <-- rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ID = cats(tmp_ID);

* Convert temporary character var for each date field to a date var *;
   OnsetDate = input(tmp_onsetdate, yymmdd10.); format OnsetDate yymmdd10.;

   DROP tmp_: ;
run;


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(&SQL_dsn._temp)


** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by %shrink macro **;
DATA COVID.&SQL_dsn ; set &SQL_dsn._temp_ ;
run;


   PROC contents data=COVID.&SQL_dsn varnum; run;













