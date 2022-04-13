/**********************************************************************************************
PROGRAM:   Access.Providers
AUTHOR:    Eric Bush
CREATED:   April 13, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.Providers
OUTPUT:		       Providers_read
***********************************************************************************************/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA Providers; set CEDRS66.Providers; run; 

** Review contents of SAS dataset **;
PROC contents data=Providers  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA Providers_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Providers(rename=
                   (ProviderID=tmp_ProviderID 
                    CreatedDate=tmp_CreatedDate
                    UpdatedDate=tmp_UpdatedDate )
                  ); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ProviderID = cats(tmp_ProviderID);

* Extract date part of a datetime variable  *;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;

   DROP tmp_:  ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Providers_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Providers_read ;  set Providers_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=Providers_read varnum; title1 'Providers_read'; run;




