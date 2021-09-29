/**********************************************************************************************
PROGRAM: Access.TimeSinceVax.sas
AUTHOR:  Eric Bush
CREATED: July 14, 2021
MODIFIED:	
PURPOSE:	A single program to read CEDRS view
INPUT:		dbo144.timesincevax_regression_data
OUTPUT:		       TimeSinceVax
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
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** schema contains "CEDRS_view, a copy of CEDRS_dashboard_constrained";


**  2. Review contents of SAS dataset  **;
PROC contents data=dbo144.timesincevax_regression_data  varnum ;  run;    

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |  ProfileID is numeric instead of a character variable.    
 |    --> Convert to character variable prior to running SHRINK macro.     
 |  Many of the character variables have length of $255.
 |    --> Use the macro "Shrink" to minimize the length of the character variables.
 *________________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA timesincevax_regression_data; 
   set dbo144.timesincevax_regression_data(rename=(Patient_ID=tmp_Patient_ID)); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   Patient_ID = cats(tmp_Patient_ID);

   DROP tmp_Patient_ID  ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(timesincevax_regression_data)


** 5. Create libname for folder to store permanent SAS dataset  **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA TimeSinceVax ; set timesincevax_regression_data_ ;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data= TimeSinceVax  varnum ; title1 'TimeSinceVax'; run;
