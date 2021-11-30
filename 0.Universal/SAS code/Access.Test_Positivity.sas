/**********************************************************************************************
PROGRAM:  Access.Test_Positivity
AUTHOR:   Eric Bush
CREATED:  November 29, 2021
MODIFIED: 	
PURPOSE:	 A single program to read CEDRS view
INPUT:		tests144.Positivity
OUTPUT:		         Positivity
***********************************************************************************************/

/*------------------------------------------------------------------------------------------------*
 | What this program does:
 | 1. Define library to access COVID19 database on dbo144 server using ODBC
 | 2. Create temp SAS dataset from SQL table and report findings
 | 3. Modify SAS dataset per Findings
 |    a) Convert temporary numeric ID variable character ID var using the CATS function
 |    b) Convert temporary character var for each date field to a date var
 |    c) Extract date part of a datetime variable
 | 4. Shrink character variables in data set to shortest possible length (based on longest value)
 | 5. Define library to store permanent SAS dataset
 | 6. Rename "shrunken" SAS dataset
 | 7. PROC contents of final dataset
 *------------------------------------------------------------------------------------------------*/

** 1. Libname to access COVID19 database on dbo144 server using ODBC **;
/*LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** schema contains "CEDRS_view, a copy of CEDRS_dashboard_constrained";*/

LIBNAME tests144  ODBC  dsn='COVID19' schema=tests;  run;


**  2. Review contents of SAS dataset  **;
PROC contents data=tests144.COVID19_positivity_Trends  varnum ;  run;    

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
DATA Positivity_temp; 
   set tests144.COVID19_positivity_Trends(rename=(date_as_of=tmp_date_as_of)); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;

* Convert temporary character var for each date field to a date var *;
   TestDate             = input(tmp_date_as_of, yymmdd10.);            format TestDate yymmdd10.;

   DROP tmp_:  ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Positivity_temp)


** 5. Create libname for folder to store permanent SAS dataset  **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Test_Positivity ; set Positivity_temp_ ;   run;


**  7. PROC contents of final dataset  **;
   PROC contents data= Test_Positivity  varnum ; title1 'Test_Positivity'; run;


** 8.  Move copy to DASHboard directory **;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;

DATA DASH.TestPositivity ; set Test_Positivity ;
   KEEP  Lab  Daily_Tests  Daily_Confirmed_only  Positivity  TestDate  ;
run;

