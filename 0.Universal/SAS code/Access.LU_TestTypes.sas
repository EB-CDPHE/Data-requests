/**********************************************************************************************
PROGRAM:   Access.LU_TestTypes
AUTHOR:    Eric Bush
CREATED:   April 14, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  Lookup66.LU_TestTypes
OUTPUT:		        LU_TestTypes_read
***********************************************************************************************/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME Lookup66 ODBC  dsn='CEDRS_III_Warehouse' schema=lookups;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA LU_TestTypes; set Lookup66.TestTypes; run; 

** Review contents of SAS dataset **;
PROC contents data=LU_TestTypes  varnum ;  run;   

** 3. Modify SAS dataset per Findings **;
DATA LU_TestTypes_temp;   set LU_TestTypes; 
run;

** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(LU_TestTypes_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA LU_TestTypes_read ;  set LU_TestTypes_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=LU_TestTypes_read ; title1 'LU_TestTypes_read'; run;



*** Explore data ***;
***--------------***;

   PROC freq data= LU_TestTypes_read;
      where TestTypeID in (99,115,229,377,434,435,439);
      tables  TestType * TestTypeID / list;
      format TestType  $30.;
run;

