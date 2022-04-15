/**********************************************************************************************
PROGRAM:    Access.LabSpecimens      
AUTHOR:		Eric Bush
CREATED:	   April 14, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on LabSpecimens
INPUT:		dbo66.LabSpecimens  
OUTPUT:		      LabSpecimens_read   AND   LabSpecimens_reduced
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/


** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;         * <--  Changed BK's libname ; 


** 2. Read in the SQL table to create initial SAS dataset **;
DATA LabSpecimens; set CEDRS66.LabSpecimens; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=LabSpecimens  varnum ; title1 'CEDRS66.LabSpecimens';  run;  


** 3. Modify SAS dataset per Findings **;
DATA LabSpecimens_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set LabSpecimens(rename=
                   (CollectionDate=tmp_CollectionDate
                    LITSReceiveDate=tmp_LITSReceiveDate
                    IsolateShipDateExpected=tmp_ShipExpected
                    IsolateShipDateActual=tmp_ShipActual
                    IsolateReShipDateExpected=tmp_ReshipExpected
                    IsolateReShipDateActual=tmp_ReshipActual
                    CreatedDate=tmp_CreatedDate
                    UpdatedDate=tmp_UpdatedDate )
                  ); 
 
* Extract date part of a datetime variable  *;
   CollectionDate = datepart(tmp_CollectionDate);  format CollectionDate yymmdd10.;
   LITSReceiveDate  =  datepart(tmp_LITSReceiveDate);   format LITSReceiveDate yymmdd10.;
   IsolateShipDateExpected = datepart(tmp_ShipExpected);  format IsolateShipDateExpected yymmdd10.;
   IsolateShipDateActual = datepart(tmp_ShipActual);  format IsolateShipDateActual yymmdd10.;
   IsolateReShipDateExpected = datepart(tmp_ReshipExpected);  format IsolateReShipDateExpected yymmdd10.;
   IsolateReShipDateActual = datepart(tmp_ReshipActual);  format IsolateReShipDateActual yymmdd10.;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;

   DROP tmp_:  ;
run;

** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(LabSpecimens_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA LabSpecimens_read ;  set LabSpecimens_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=LabSpecimens_read varnum; title1 'LabSpecimens_read'; run;

   proc freq data=LabSpecimens_read;
      tables LITSSpecimenID ;
run;
