/**********************************************************************************************
PROGRAM:   Access.Hospitalizations
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  dbo66.GetProfiles
OUTPUT:		     GetProfiles_read
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

LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA Hospitalizations; set CEDRS66.Hospitalizations; 
/*   if DiseaseID =159  AND   EventStatusID in (1, 2)   AND  Deleted=0 ;*/
/*   if disease ='COVID-19'  AND   EventStatus in ('Probable','Confirmed')   AND  Deleted=0 ;*/
run; 

** Review contents of SAS dataset **;
PROC contents data=Hospitalizations  varnum ;  run;   
