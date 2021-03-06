/**********************************************************************************************
PROGRAM:   Access.UnitedStateTrips
AUTHOR:    Eric Bush
CREATED:   April 17, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.USA_Trips
OUTPUT:		       USA_Trips_read
***********************************************************************************************/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA USA_Trips; set CEDRS66.UnitedStateTrips; run; 

** Review contents of SAS dataset **;
PROC contents data=USA_Trips  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA USA_Trips_read;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set USA_Trips(rename=
                   (CreatedDate=tmp_CreatedDate
                    UpdatedDate=tmp_UpdatedDate )
                  ); 
 
* Extract date part of a datetime variable  *;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;

   DROP tmp_:  ;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=USA_Trips_read varnum; title1 'USA_Trips_read'; run;



   PROC freq data= USA_Trips_read order = freq;
      tables StateID ;
run;

