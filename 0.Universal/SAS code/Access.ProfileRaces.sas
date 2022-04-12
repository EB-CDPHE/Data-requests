/**********************************************************************************************
PROGRAM:   Access.ProfileRaces
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.GetProfiles
OUTPUT:		       GetProfiles_read
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
DATA ProfileRaces; set CEDRS66.ProfileRaces; run; 

** Review contents of SAS dataset **;
PROC contents data=ProfileRaces  varnum ;  run;   

** 3. Modify SAS dataset per Findings **;
DATA ProfileRaces_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set ProfileRaces(rename=
                   (ProfileID=tmp_ProfileID 
                    UpdatedDate=tmp_UpdatedDate
                    CreatedDate=tmp_CreatedDate )
                  ); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ProfileID = cats(tmp_ProfileID);

* Extract date part of a datetime variable  *;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;

   DROP tmp_:  ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(ProfileRaces_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA ProfileRaces_read ;  set ProfileRaces_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=ProfileRaces_read varnum; title1 'ProfileRaces_read'; run;



