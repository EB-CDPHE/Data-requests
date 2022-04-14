/**********************************************************************************************
PROGRAM:   Access.Employment
AUTHOR:    Eric Bush
CREATED:   April 13, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.Employment
OUTPUT:		       Employment_read
***********************************************************************************************/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA Employment; set CEDRS66.Employment; run; 

** Review contents of SAS dataset **;
PROC contents data=Employment  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA Employment_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Employment(rename=
                   (ProfileID=tmp_ProfileID 
                    StartDate=tmp_StartDate
                    EndDate=tmp_EndDate

                    CreatedDate=tmp_CreatedDate
                    UpdatedDate=tmp_UpdatedDate )
                  ); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ProfileID = cats(tmp_ProfileID);

* Extract date part of a datetime variable  *;
   StartDate = datepart(tmp_StartDate);  format StartDate yymmdd10.;
   EndDate  =  datepart(tmp_EndDate);   format EndDate yymmdd10.;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;

   DROP tmp_:  ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Employment_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Employment_read ;  set Employment_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=Employment_read varnum; title1 'Employment_read'; run;




*** Explore data ***;
***--------------***;

   proc print data=Employment_read;
      where CodeID in (277, 278, 279);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

   PROC freq data= Employment_read;
/*      tables EmploymentID;*/
/*      tables OccupationID;*/
      tables OtherOccupation;
run;

