/**********************************************************************************************
PROGRAM:   Access.COVID19Contacts
AUTHOR:    Eric Bush
CREATED:   April 17, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.COVID19Contacts
OUTPUT:		       COVID19Contacts_read
***********************************************************************************************/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA COVID19Contacts; set CEDRS66.COVID19Contacts; run; 

** Review contents of SAS dataset **;
PROC contents data=COVID19Contacts  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA COVID19Contacts_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set COVID19Contacts(rename=
                   (CreatedDate=tmp_CreatedDate
                    UpdatedDate=tmp_UpdatedDate )
                  ); 
 
* Extract date part of a datetime variable  *;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;

   DROP tmp_:  ;
run;

** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(COVID19Contacts_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COVID19Contacts_read ;  set COVID19Contacts_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=COVID19Contacts_read varnum; title1 'COVID19Contacts_read'; run;


*** Explore data ***;
***--------------***;


   PROC freq data= COVID19Contacts_read;
      tables ContactTypeHousehold;
run;

