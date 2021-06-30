/**********************************************************************************************
PROGRAM: Check.[CEDRS_SQL_table]
AUTHOR:  Eric Bush
CREATED: June 8, 2021
MODIFIED:	
PURPOSE:	This code offers a menu of data checks for newly created SAS dataset.
         For example, a dataset that is created from a SQL data table that has been read using Read.[CEDRS_SQL_table] program. 
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

/*________________________________________________________________________________________________________*
 | Table of Contents - code for the following tasks:
 | *** FIRST CHANGE PROGRAM NAME IN HEADER AND SAVE FILE WITH THIS NEW NAME. ***
 |    Complete libname statement to point to SAS dataset created with the matching Read.* program.
 |    A. Explore Admin variables such as ID variables.
 |       1. Check for duplicate records. 
 |       2. Print selected admin variables for specific duplicate records.
 |       3. Check of missing values in Admin variables - char var (or categorical data)
 |       4. Check of missing values in Admin variables - numeric var
 |
 |    B. Explore Event Dates.
 |       1. Check completeness of selected date variables
 |       2. Check for invalid date values via Proc Freq and various time formats
 |
 |    C. Explore Demographic variables.
 |       1. Print selected demographic variables for specific record.
 *________________________________________________________________________________________________________*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COVID.SQL_dsn varnum; run;


*** A. Admin variables ***;
***-----------------***;

* A.1: Check for (and identify) duplicate records *;
   ** --> for CEDRS, each record should have a unique (ProfileID || EventID)  **;
   PROC FREQ data= COVID.SQL_dsn  noprint;  
      tables ProfileID * EventID / out=DupChk(where= count>1);    * <-- output ID's for dup records into DupChk dataset;
   PROC print data=DupChk;  id ProfileID;  run;

* A.2: Print out record for specific Profile ID (or subsitute or add Event ID) *;
   PROC print data= COVID.SQL_dsn;
      where ProfileID='1234567';
      id ProfileID; 
      var EventID  LastName FirstName ReportedDate ;
run;

* A.3: Check for missing values in Admin variables - char var *;
   PROC freq data= COVID.SQL_dsn;
     tables ID * ProfileID * EventID /list missing missprint;
run;

* A.4: Check for missing values in Admin variables - numeric var *;
   PROC means data= COVID.SQL_dsn  n nmiss ;
     var Hosp_Date;
run;


*** B. Event dates  ***;
***-----------------***;

** B.1 Check completeness of selected date variables **;
   PROC print data= COVID.SQL_dsn;
      ID ID ;
      var OnsetDate_proxy_dist  Earliest_CollectionDate  CollectionDate  ReportedDate  DeathDate  ;
run;

** B.2 Check for invalid date values via Proc Freq and various time formats (e.g. Month, Day of week, Week) **;
   PROC freq data= COVID.SQL_dsn;  tables reporteddate;  format reporteddate MONYY. ;  run;
   PROC freq data= COVID.SQL_dsn;  tables reporteddate;  format reporteddate DOWNAME. ; run;
   PROC freq data= COVID.SQL_dsn;  tables reporteddate;  format reporteddate WeekW5. ; run;


*** C. Demographic variables  ***;
***---------------------------***;

** C.1 Print selected demographic variables for specific record. **;
   PROC print data= COVID.SQL_dsn;
      where ProfileID in ('1618760', '1646961', '1664420', '1678755');
      ID ProfileID ;
      var EventID   Gender   Age_at_Reported   Age_Group   Single_Race_Ethnicity   CountyAssigned   ReportedDate   ONsetDate 
          Hospitalized   ICU   Transmission_Type   LiveInInstitution   Outcome   CaseStatus   Homeless   Reinfection   Outbreak_Associated  Breakthrough
          Deathdate  Vax_Utd ;
run;
