/**********************************************************************************************
PROGRAM:    Read.SurvFormBase      
AUTHOR:		Eric Bush
CREATED:	   July 5, 2021
MODIFIED:   
PURPOSE:	   Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		dbo144.CEDRS_view
OUTPUT:		COVID.CEDRS_view
***********************************************************************************************/

/*________________________________________________________________________________________________________*
 | Required user input for this code to work:
 |    1. Complete libname stm with Libref, dsn, and schema.  See CEDRS.Libnames.sas
 |    2. Insert libref into Data step. Explore work folder to get name of data table and add to set statement.
 |       *This data step will be run twice.
 |       a. The first time, use obs=50 option. Review proc contents output.
 |       b. Record findings. See expected findings below.
 |    3. Modify second Data step per findings. Creates a temporary data set.
 |    4. Shrink character variables in data set to shortest possible lenght (based on longest value).
 |       ** Get Macro.Shrink.sas program from GitHub repository "SAS-code-library".
 |       ** NOTE: macro saves to new dataset by adding "_" to end of dataset name provided by user.
 |    5. Create libname for folder to store permanent SAS dataset (if desired). e.g on J: drive.
 |    6. Rename "shrunken" SAS dataset by removing underscore added by macro.
 *________________________________________________________________________________________________________*/

** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;         * <--  Changed BK's libname ; 


** 2. Read in the first 50 records to create sample SAS dataset **;
DATA SurvFormBase; set CEDRS66.SurveillanceFormBase; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=SurvFormBase  varnum ;  run;    

/*----*
 |FINDINGS:
 | All variables have only NULL values, EXCEPT for the following:
 | KEEP  FormBaseID  EventID  DiseaseID  UpdateDate  CreateDate;
 *--------------------*/

** 3. Modify SAS dataset per Findings **;
DATA SurvFormBase_temp;    
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set SurvFormBase(rename=
                   (DateOfBirth=tmp_DateOfBirth
                    DateReportedCDC=tmp_DateReportedCDC
                    EventDate=tmp_EventDate
                    DateReportedCDPHE=tmp_DateReportedCDPHE
                    DateReportedLHD=tmp_DateReportedLHD
                    OnsetDate=tmp_OnsetDate
                    DiagnosisDate=tmp_DiagnosisDate
                    UpdateDate=tmp_UpdateDate
                    CreateDate=tmp_CreateDate )
                  ); 
 
* Extract date part of a datetime variable  *;
   DateOfBirth = datepart(tmp_DateOfBirth);    format DateOfBirth yymmdd10.;
   DateReportedCDC = datepart(tmp_DateReportedCDC);   format DateReportedCDC yymmdd10.;
   EventDate = datepart(tmp_EventDate);    format EventDate yymmdd10.;
   DateReportedCDPHE = datepart(tmp_DateReportedCDPHE);    format DateReportedCDPHE yymmdd10.;
   DateReportedLHD = datepart(tmp_DateReportedLHD);    format DateReportedLHD yymmdd10.;
   OnsetDate = datepart(tmp_OnsetDate);    format OnsetDate yymmdd10.;
   DiagnosisDate = datepart(tmp_DiagnosisDate);    format DiagnosisDate yymmdd10.;
   UpdateDate = datepart(tmp_UpdateDate);    format UpdateDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);    format CreateDate yymmdd10.;

/*   DROP tmp_:  ;*/
   KEEP  FormBaseID  EventID  DiseaseID  UpdateDate  CreateDate;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(SurvFormBase_temp)

** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA SurvFormBase_read;  set SurvFormBase_temp_;  run;

**  7. PROC contents of final dataset  **;
   PROC contents data=SurvFormBase_read varnum; title1 'SurvFormBase_read'; run; 






