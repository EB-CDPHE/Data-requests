/**********************************************************************************************
PROGRAM:   Access.GetEventStatus
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.zDSI_Events.sas	
PURPOSE:   Access SQL table on Events
INPUT:	  Lookup66.GetEventStatus
OUTPUT:		        GetEventStatus_read
***********************************************************************************************/

/*--------------------------------------------------------------------*
 | What this program does:
 | 1. Define library to access COVID19 database on dbo144 server using ODBC
 | 2. Create temp SAS dataset from SQL table and report findings
 | 3. Modify SAS dataset per Findings
 |    a) Convert temporary numeric ID variable character ID var using the CATS function
 | 4. Shrink character variables in data set to shortest possible length (based on longest value)
 | 5. Define library to store permanent SAS dataset
 | 6. Rename "shrunken" SAS dataset
 | 7. PROC contents of final dataset
 *--------------------------------------------------------------------*/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME Lookup66 ODBC  dsn='CEDRS_III_Warehouse' schema=lookups;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA GetEventStatus; set Lookup66.GetEventStatus; 
run; 

** Review contents of SAS dataset **;
PROC contents data=GetEventStatus  varnum ;  run;  


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(GetEventStatus)

** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA GetEventStatus_read;  set GetEventStatus_;  run;

**  7. PROC contents of final dataset  **;
   PROC contents data=GetEventStatus_read varnum; title1 'GetEventStatus_read'; run; 

   PROC print data=GetEventStatus_read ;  run; 
