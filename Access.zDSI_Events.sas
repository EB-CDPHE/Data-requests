/**********************************************************************************************
PROGRAM:   Access.zDSI_Events
AUTHOR:    Eric Bush
CREATED:   July 14, 2021
MODIFIED:  081321:  Add filter for DELETED=0	
PURPOSE:   Access SQL table on Events
INPUT:	  dbo66.zDSI_Events
OUTPUT:		     zDSI_Events_read
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

/*_______________________________________________________*
 |NOTE:  
 | ** DiseaseID=159 for Disease='COVID-19'
 | ** EventStatusID=1 for EventStatus='Confirmed'
 | ** EventStatusID=2 for EventStatus='Probable'
 | ** AgeTypeID=1 for AgeType='years'
 | ** AgeTypeID=2 for AgeType='months'
 | ** AgeTypeID=3 for AgeType='weeks'
 | ** AgeTypeID=4 for AgeType='days'
 | ** AgeTypeID=9 for AgeType='unknown'
 *_______________________________________________________*/


**  2. Create temp SAS dataset from SQL table  **;
DATA zDSI_Events; set CEDRS66.zDSI_Events(keep=ProfileID EventID  DiseaseID  EventStatusID  AgeTypeID  Age Deleted); 
/*   if disease ='COVID-19'  AND   EventStatus in ('Probable','Confirmed')   AND  Deleted=0 ;*/
   if DiseaseID =159  AND   EventStatusID in (1, 2)   AND  Deleted=0 ;
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
DATA zDSI_Events_read ;  length ProfileID $ 9;  set zDSI_Events_temp_ ;
   format ProfileID $9.;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=zDSI_Events_read varnum; run;


