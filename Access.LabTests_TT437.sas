/**********************************************************************************************
PROGRAM:    Access.LabTests_TT437      
AUTHOR:		Eric Bush
CREATED:	   August 20, 2021
MODIFIED:   
PURPOSE:	   Connect to CEDRS backend (dphe66) to access LabTests
INPUT:		dbo66.zDSI_LabTests  WHERE TestTypeID= 437 (TestType = 'COVID-19 Variant Type')
OUTPUT:		      LabTests_read
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
DATA LabTests; set CEDRS66.zDSI_LabTests; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=LabTests  varnum ; title1 'CEDRS66.zDSI_LabTests';  run;  

   PROC freq data = LabTests;
      tables TestTypeID * TestType /list; 
run;
proc print data= LabTests; where TestType = 'RT-PCR'; var TestTypeID TestType ResultID ResultText QuantitativeResult; run;

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    EventID is a numeric instead of character variable.    
 |    (Convert to character prior to running SHRINK macro.)    
 |    CreatedDate is a date-time variable. Extract date part and create date variable.
 |    Character vars have length and format of $255. Keep just the two new variables plus ICU.
 |
 |NOTE:  
 | ** TestTypeID=229 for TestType = 'RT-PCR'
 | ** TestTypeID=435 for TestType = 'Antigen for COVID-19'
 | ** TestTypeID=436 for TestType = 'Variant of public health concern'
 | ** TestTypeID=437 for TestType = 'COVID-19 Variant Type'
 *________________________________________________________________________________________________*/

   PROC freq data = LabTests;
      where TestType = 'COVID-19 Variant Type' ;
      tables TestTypeID * TestType /list; 
run;


** 3. Modify SAS dataset per Findings **;
DATA COVID_LabTests; 
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set LabTests(rename=
                (EventID    = tmp_EventID
                 ResultDate = tmp_ResultDate
                 CreateDate = tmp_CreateDate
                 UpdateDate = tmp_UpdateDate)
                 );     

* restrict to just COVID sequencing results *;
   where TestType = 'COVID-19 Variant Type' ;
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);

* Convert temporary character var for each date field to a date var *;
/*   OnsetDate = input(tmp_onsetdate, yymmdd10.); format OnsetDate yymmdd10.;*/

* Extract date part of a datetime variable  *;
   ResultDate = datepart(tmp_ResultDate);   format ResultDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);   format CreateDate yymmdd10.;
   UpdateDate = datepart(tmp_UpdateDate);   format UpdateDate yymmdd10.;

   DROP tmp_: ;
/*   Keep EventID  CreatedDate;*/
run;

   PROC contents data=COVID_LabTests varnum ; title1 'COVID_LabTests'; run;


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(COVID_LabTests)



** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA LabTests_read ; set COVID_LabTests_;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=LabTests_read  varnum ;  title1 'LabTests_read';  run;
