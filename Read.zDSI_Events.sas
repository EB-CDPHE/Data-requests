/**********************************************************************************************
PROGRAM: Read.zDSI_Events
AUTHOR:  Eric Bush
CREATED: July 14, 2021
MODIFIED:	
PURPOSE:	A single program to read CEDRS view
INPUT:		dbo66.zDSI_Events
OUTPUT:		      zDSI_Events_read
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
LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;         * <--  Changed BK's libname ; 


**  2. Create temp SAS dataset from SQL table  **;
DATA zDSI_Events; set CEDRS66.zDSI_Events(keep=ProfileID EventID Disease EventStatus AgeTypeID AgeType Age   MedicalRecordNumber); 
   if disease ='COVID-19'  AND   EventStatus in ('Probable','Confirmed') ;
run; 

** Review contents of SAS dataset **;
PROC contents data=zDSI_Events  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA zDSI_Events_temp; set zDSI_Events(rename=(EventID=tmp_EventID ProfileID=tmp_ProfileID )); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);
   ProfileID = cats(tmp_ProfileID);
   DROP tmp_:  ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(zDSI_Events_temp)


** 5. Create libname for folder to store permanent SAS dataset  **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA zDSI_Events_read ; set zDSI_Events_temp_ ;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=zDSI_Events_read varnum; run;


