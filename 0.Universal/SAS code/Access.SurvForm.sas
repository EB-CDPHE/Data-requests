/**********************************************************************************************
PROGRAM:    Read.SurvForm      
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
DATA SurvForm; set CEDRS66.SurveillanceFormCovid19; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=SurvForm  varnum ;  run;    


/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    EventID is a numeric instead of character variable.    
 |    (Convert to character prior to running SHRINK macro.)    
 |    CreatedDate is a date-time variable. Extract date part and create date variable.
 |    Character vars have length and format of $255. Keep just the two new variables plus ICU.
 *________________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA SurvForm_temp; set SurvForm(rename=
         (EventID=tmp_EventID CreatedDate=tmp_CreatedDate));     * <-- rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);

* Convert temporary character var for each date field to a date var *;
/*   OnsetDate = input(tmp_onsetdate, yymmdd10.); format OnsetDate yymmdd10.;*/

* Extract date part of a datetime variable  *;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;

   DROP tmp_: ;
/*   Keep EventID ICU CreatedDate;*/
run;

   PROC contents data=SurvForm_temp  ; run;


DATA SurvForm_read; 
   length EventID $ 7; ;
   set SurvForm_temp ;
   format EventID $7. ;
   rename ICU = ICU_SurvForm;
run;

   PROC contents data=SurvForm_read  ; run;



*** Explore data ***;
***--------------***;

   proc freq data=SurvForm_read;
/*      tables ICU_SurvForm  ;*/
      tables VaccineBreakthrough  ;
/*      tables  ExposureOccurredCountyID ;*/

run;
