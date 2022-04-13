/**********************************************************************************************
PROGRAM:   Access.Addresses
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.Addresses_read
OUTPUT:		       Addresses_read
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
DATA Addresses; set CEDRS66.Addresses; 
/*   if DiseaseID =159  AND   EventStatusID in (1, 2)   AND  Deleted=0 ;*/
/*   if disease ='COVID-19'  AND   EventStatus in ('Probable','Confirmed')   AND  Deleted=0 ;*/
run; 

** Review contents of SAS dataset **;
PROC contents data=Addresses  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA Addresses_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Addresses(rename=
                   (ProfileID=tmp_ProfileID 
                    DeactivatedDate=tmp_DeactivatedDate
                    UpdatedDate=tmp_UpdatedDate
                    CreatedDate=tmp_CreatedDate
                    GeoCodedDate=tmp_GeoCodedDate )
                  ); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ProfileID = cats(tmp_ProfileID);

* Extract date part of a datetime variable  *;
   DeactivatedDate = datepart(tmp_DeactivatedDate);   format DeactivatedDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;
   GeoCodedDate = datepart(tmp_GeoCodedDate);   format GeoCodedDate yymmdd10.;

   DROP tmp_:  ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Addresses_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Addresses_read ;  set Addresses_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=Addresses_read varnum; title1 'Addresses_read'; run;



*** Explore data ***;
***--------------***;

   proc freq data=Addresses_read;
      tables AddressID ;
run;

