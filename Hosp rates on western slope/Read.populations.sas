/**********************************************************************************************
PROGRAM:    Read.populations
AUTHOR:		Eric Bush
CREATED:	   June 24, 2021
MODIFIED:   	
PURPOSE:	   Connect to dphe144 "populations" and create associated SAS dataset.
            Modify "group" variable so that it only contains county name.
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

/*________________________________________________________________________________________________________*
 | Table of contents:
 |    1. Use libname dbo144 to access dbo schema.  See CEDRS.Libnames.sas
 |    2. Make temporary copy of the Populations data table in the dbo schema 
 |       a) Review contents
 |    3. Modify second Data step per findings. 
 |    4. Shrink character variables in data set to shortest possible length (based on longest value).
 |       ** Get Macro.Shrink.sas program from GitHub repository "SAS-code-library".
 |       ** NOTE: macro saves to new dataset by adding "_" to end of dataset name provided by user.
 |    6. Create libname for folder to store permanent SAS dataset (if desired). e.g on J: drive.
 |    7. Rename "shrunken" SAS dataset by removing underscore added by macro.
 *________________________________________________________________________________________________________*/

*** County Population data ***;
***------------------------***;

** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

** 2. Read in the first 50 records to create sample SAS dataset **;
DATA COPHS; set dbo144.populations; run;    * <-- for building code add (obs=50) ;

** 2.a) Review contents of SAS dataset **;
PROC contents data=dbo144.populations  varnum ;  run;    

/*----------------------------------------------------------------------------------------------*
 |FINDINGS:
 | Group variable contains 3 different variable values: County name, Age group, and Gender.
 | --> delete Age group and Gender values and rename Group variable to County.
 *----------------------------------------------------------------------------------------------*/

** 3. Modify SAS dataset per Findings **;

DATA Pop_temp; set dbo144.populations(Rename=(Group=County)); 
   if index(County,'yrs')>0  then delete;
   if County in ('Female', 'Male') then delete;
run;

** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Pop_temp)

*  --> output dsn will be "COPHS_temp_"   (NOTE: underscore appended to end of dsn) ;

** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COVID.County_Population ; set Pop_temp_ ;
run;

   PROC contents data=COVID.County_Population varnum; run;


