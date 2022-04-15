/**********************************************************************************************
PROGRAM:   Access.LU_Results
AUTHOR:    Eric Bush
CREATED:   April 14, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  Lookup66.Results
OUTPUT:		        Results_read
***********************************************************************************************/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME Lookup66 ODBC  dsn='CEDRS_III_Warehouse' schema=lookups;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA LU_Results; set Lookup66.Results; run; 

** Review contents of SAS dataset **;
PROC contents data=LU_Results  varnum ;  run;   

** 3. Modify SAS dataset per Findings **;
DATA Results_temp;   set LU_Results; 
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Results_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA LU_Results_read ;  set Results_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=LU_Results_read varnum; title1 'LU_Results_read'; run;



*** Explore data ***;
***--------------***;

   PROC freq data= LU_Results_read;
      tables ResultID * ResultText  /list;
/*      tables  ResultText;*/
run;

