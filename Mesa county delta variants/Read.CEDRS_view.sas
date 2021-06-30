/**********************************************************************************************
PROGRAM:    Read.CEDRS_view      [ <-- from Read.CEDRS_SQL_table.sas template ]
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
 |    2. Insert libref into Data step. Explore work folder to get name of data table and add to set statement.
 |       *This data step will be run twice.
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
DATA CEDRS_view; set dbo144.CEDRS_view; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=CEDRS_view  varnum ;  run;    

/* Look for ID variables that are numeric */
/* Look for date fields that are character variables */
/* Document findings below */

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |  ID, ProfileID and EventID are numeric instead of character variables.    
 |    --> These need to be converted to character variables prior to running SHRINK macro.     
 |  The following date fields are character variables instead of a numeric variable with date format.
 |    OnsetDate, onsetdate_proxy, onsetdate_proxy_dist, ReportedDate, CollectionDate, DeathDate, 
 |    Earliest_CollectionDate, Data_pulled_as_of
 |    --> ignore onsetdate_proxy; use onsetdate_proxy_dist instead (per Rachel S.)
 |    --> convert these fields to SAS date variables.
 |  Many of the character variables have length of $255.
 |    --> Use the macro "Shrink" to minimize the length of the character variables.
 *________________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA CEDRS_view_temp; set CEDRS_view(rename=
   (ID=tmp_ID ProfileID=tmp_ProfileID EventID=tmp_EventID
    OnsetDate=tmp_OnsetDate  OnsetDate_proxy_dist=tmp_OnsetDate_proxy_dist 
    ReportedDate=tmp_ReportedDate CollectionDate=tmp_CollectionDate  DeathDate=tmp_DeathDate
    Earliest_CollectionDate=tmp_Earliest_CollectionDate   Data_pulled_as_of=tmp_Data_pulled_as_of 
   )); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ID = cats(tmp_ID);
   ProfileID = cats(tmp_ProfileID);
   EventID = cats(tmp_EventID);

* Convert temporary character var for each date field to a date var *;
   OnsetDate            = input(tmp_onsetdate, yymmdd10.);            format OnsetDate yymmdd10.;
   OnsetDate_proxy_dist = input(tmp_OnsetDate_proxy_dist, yymmdd10.); format OnsetDate_proxy_dist yymmdd10.;
   ReportedDate         = input(tmp_ReportedDate, yymmdd10.);         format ReportedDate yymmdd10.;
   CollectionDate       = input(tmp_CollectionDate, yymmdd10.);       format CollectionDate yymmdd10.;
   DeathDate            = input(tmp_DeathDate, yymmdd10.);            format DeathDate yymmdd10.;
   Earliest_CollectionDate = input(tmp_Earliest_CollectionDate, yymmdd10.); format Earliest_CollectionDate yymmdd10.;
   Data_pulled_as_of     = input(tmp_Data_pulled_as_of, yymmdd10.);   format Data_pulled_as_of yymmdd10.;

   DROP tmp_:  address:  OnsetDate_proxy ;
run;


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(CEDRS_view_temp)


** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COVID.CEDRS_view ; set CEDRS_view_temp_ ;
run;


   PROC contents data=COVID.CEDRS_view varnum; run;













