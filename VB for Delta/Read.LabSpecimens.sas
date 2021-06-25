/**********************************************************************************************
PROGRAM:    Read.LabSpecimens
AUTHOR:		Eric Bush
CREATED:	   June 7, 2021
MODIFIED:   060921:  remove macro Shrink from code and add %inc statement to read it instead	
PURPOSE:	   Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

/*________________________________________________________________________________________________________*
 | Required user input for this code to work:
 | *** FIRST CHANGE PROGRAM NAME IN HEADER AND SAVE FILE WITH THIS NEW NAME. ***
 |    1. Complete libname stm with Libref, dsn, and schema.  See CEDRS.Libnames.sas
 |    2. Insert libref and dsn into Data step. This data step will be run twice.
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
LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

** 2. Read in the first 50 records to create sample SAS dataset **;
DATA LabSpecimens(Keep= LabSpecimenID EventID LITSSpecimenID) ; set CEDRS66.LabSpecimens; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=LabSpecimens  varnum ;  run;    

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    EventID is a numeric instead of character variable. 
 |    EventID should have length of 7 to merge   
 *________________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA LabSpecimens_char;  length EventID $ 7 ;  set LabSpecimens(rename=(EventID=tmp_EventID )); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);

   DROP tmp_: ;
run;

   PROC contents data=LabSpecimens_char varnum; run;











