/**********************************************************************************************
PROGRAM:   Access.ForeignTrips
AUTHOR:    Eric Bush
CREATED:   April 17, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.ForeignTrips
OUTPUT:		       ForeignTrips_read
***********************************************************************************************/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA ForeignTrips; set CEDRS66.ForeignTrips; run; 

** Review contents of SAS dataset **;
PROC contents data=ForeignTrips  varnum ;  run;   

** 3. Modify SAS dataset per Findings **;
DATA ForeignTrips_read;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set ForeignTrips(rename=
                   (CreatedDate=tmp_CreatedDate
                    UpdatedDate=tmp_UpdatedDate )
                  ); 
 
* Extract date part of a datetime variable  *;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;

   DROP tmp_:  ;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=ForeignTrips_read varnum; title1 'ForeignTrips_read'; run;



   PROC freq data= ForeignTrips_read order = freq;
/*      tables CountryID ;*/
      tables StateID ;
run;

