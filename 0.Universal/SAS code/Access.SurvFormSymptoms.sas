/**********************************************************************************************
PROGRAM:    Access.SurvFormSymptoms      
AUTHOR:		Eric Bush
CREATED:	   July 5, 2021
MODIFIED:   
PURPOSE:	   Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		dbo144.SurveillanceFormSymptoms
OUTPUT:		       SurvFormSymp.read
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
DATA SurvFormSymp; set CEDRS66.SurveillanceFormSymptoms; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=SurvFormSymp  varnum ;  run;  


** 3. Modify SAS dataset per Findings **;
DATA SurvFormSymp_temp;    
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set SurvFormSymp(rename=
                   (SymptomOnsetDate=tmp_SymptomOnsetDate
                    RashOnsetDate=tmp_RashOnsetDate
                    OnsetTime=tmp_OnsetTime
                    DiarrheaOnset=tmp_DiarrheaOnset
                    CoughOnsetDate=tmp_CoughOnsetDate
                    FinalInterviewDate=tmp_FinalInterviewDate
                    JaundiceOnsetDate=tmp_JaundiceOnsetDate
                    SwellingOnsetDate=tmp_SwellingOnsetDate
                    UpdateDate=tmp_UpdateDate
                    CreateDate=tmp_CreateDate )
                  ); 
 
* Extract date part of a datetime variable  *;
   SymptomOnsetDate = datepart(tmp_SymptomOnsetDate);    format SymptomOnsetDate yymmdd10.;
   RashOnsetDate = datepart(tmp_RashOnsetDate);   format RashOnsetDate yymmdd10.;
   OnsetTime = datepart(tmp_OnsetTime);    format OnsetTime yymmdd10.;
   DiarrheaOnset = datepart(tmp_DiarrheaOnset);    format DiarrheaOnset yymmdd10.;
   CoughOnsetDate = datepart(tmp_CoughOnsetDate);    format CoughOnsetDate yymmdd10.;
   FinalInterviewDate = datepart(tmp_FinalInterviewDate);    format FinalInterviewDate yymmdd10.;
   JaundiceOnsetDate = datepart(tmp_JaundiceOnsetDate);    format JaundiceOnsetDate yymmdd10.;
   SwellingOnsetDate = datepart(tmp_SwellingOnsetDate);    format SwellingOnsetDate yymmdd10.;
   UpdateDate = datepart(tmp_UpdateDate);    format UpdateDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);    format CreateDate yymmdd10.;

   DROP tmp_:  ;
/*   KEEP  FormBaseID  EventID  DiseaseID  UpdateDate  CreateDate;*/
run;



** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(SurvFormSymp_temp)

** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA SurvFormSymp_read;  set SurvFormSymp_temp_;  run;

**  7. PROC contents of final dataset  **;
   PROC contents data=SurvFormSymp_read ; title1 'SurvFormSymp_read'; run; 




*** Explore data ***;
***--------------***;

   proc freq data=SurvFormSymp_read;
/*      tables Symptoms SymptomResolved ;*/
/*      tables Fever  FeverOver100_4  FeverChills ;*/
      tables AnyCough  RunnyNose  BodyAches  SoreThroat Dyspnea  Headache  Diarrhea  Vomiting  AbdoPain  TasteSmell;

run;

 
