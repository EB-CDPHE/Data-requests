/**********************************************************************************************
PROGRAM:   Access.GetDiseases
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.zDSI_Events.sas	
PURPOSE:   Access SQL table on Events
INPUT:	  Lookup66.GetDiseases
OUTPUT:		        GetDiseases_read
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
DATA GetDiseases; set Lookup66.GetDiseases; 
/*   if DiseaseID =159  ;*/
run; 
/*--------------------------------------------------------------------------------------------------*
 |NOTE: For DiseaseGroupName='COVID-19': DiseaseName='COVID-19', DiseaseID=159, DiseaseGroupID=9
 *--------------------------------------------------------------------------------------------------*/

** Review contents of SAS dataset **;
PROC contents data=GetDiseases  varnum ;  run;  

** 3. Modify SAS dataset per Findings **;
/*DATA GetDiseases;   set GetDiseases;  run;*/

** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(GetDiseases)

** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA GetDiseases_read;  set GetDiseases_;  run;

**  7. PROC contents of final dataset  **;
   PROC contents data=GetDiseases_read varnum; title1 'GetDiseases_read'; run; 

   PROC print data=GetDiseases_read ;  run; 
