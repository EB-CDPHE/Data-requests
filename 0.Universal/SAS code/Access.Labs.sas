/**********************************************************************************************
PROGRAM:   Access.Labs
AUTHOR:    Eric Bush
CREATED:   April 13, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.Labs
OUTPUT:		       Labs_read
***********************************************************************************************/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA Labs; set CEDRS66.Labs; run; 

** Review contents of SAS dataset **;
PROC contents data=Labs  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;

DATA Labs_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Labs(rename=
                   (ResultDate=tmp_ResultDate
                    CreateDate=tmp_CreateDate
                    UpdateDate=tmp_UpdateDate )
                  ); 
 
* Extract date part of a datetime variable  *;
   ResultDate = datepart(tmp_ResultDate);  format ResultDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);   format CreateDate yymmdd10.;
   UpdateDate = datepart(tmp_UpdateDate);   format UpdateDate yymmdd10.;

   DROP tmp_:  ;
run;

** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Labs_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Labs_read ;  set Labs_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=Labs_read ; title1 'Labs_read'; run;


*** Explore data ***;
   PROC freq data= Labs_read ;
      where TestTypeID = 437 and ResultID ^in (1067, 1068, 1070, 9);
      tables TestTypeID * ResultID / list;
run;
