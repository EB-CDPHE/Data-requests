/**********************************************************************************************
PROGRAM:   Access.Codes
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.zDSI_Events.sas	
PURPOSE:   Access SQL table on Events
INPUT:	  Lookup66.Codes
OUTPUT:		        Codes_read
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

LIBNAME Lookup66 ODBC  dsn='CEDRS_III_Warehouse' schema=lookups;  run;

**  2. Create temp SAS dataset from SQL table  **;
DATA Codes; set Lookup66.Codes; 
run; 

** Review contents of SAS dataset **;
PROC contents data=Codes  varnum ;  run;  

** 3. Modify SAS dataset per Findings **;
DATA Codes_temp;    
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Codes(rename=
                   (EffectiveDate=tmp_EffectiveDate
                    ExpirationDate=tmp_ExpirationDate )
                  ); 
 
* Extract date part of a datetime variable  *;
   EffectiveDate = datepart(tmp_EffectiveDate);    format EffectiveDate yymmdd10.;
   ExpirationDate = datepart(tmp_ExpirationDate);   format ExpirationDate yymmdd10.;

   DROP tmp_:  ;
run;

** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Codes_temp)

** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Codes_read;  set Codes_temp_;  run;

**  7. PROC contents of final dataset  **;
   PROC contents data=Codes_read varnum; title1 'Codes_read'; run; 

   PROC print data=Codes_read ; id CodeID; run; 



*** Explore data ***;
***--------------***;

   proc print data=Codes_read;
      where CodeID in (277, 278, 279);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

/*      tables ActiveAddressID ;*/
/*      tables CountyAssignedID ;*/
/*      tables EventStatusID ;*/
      tables OutcomeID ;
run;

