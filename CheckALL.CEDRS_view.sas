/**********************************************************************************************
PROGRAM: CheckALL.CEDRS_view
AUTHOR:  Eric Bush
CREATED: July 14, 2021
MODIFIED:	
PURPOSE:	Comprehensive list (pulled across all RFI folders) of data checks for CEDRS view
INPUT:		COVID.CEDRS_view   (?? change to:  COVID.CEDRS_read  ??)
OUTPUT:		printed output
***********************************************************************************************/

/*--------------------------------------------------------------------*
 | Check CEDRS_read data for:
 | 1. Duplicate records (per ProfileID - EventID)
 | 2. Invalid values for Age_at_Reported
 | 3. Completeness of date variables
 | 4. Invalid values for ICU variable
 | 5. Invalid values for CountyAssigned variable
 | 6. Missing keys and differing formatting (ProfileID and EventID)
 | 7. 
 *--------------------------------------------------------------------*/


***  Access CEDRS.view using ODBC  ***;
***--------------------------------***;

LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

LIBNAME COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COVID.CEDRS_view varnum; run;



***  1. Duplicate records  ***;
***------------------------***;

* Identify duplicate records;
   PROC FREQ data= COVID.CEDRS_view noprint;  
      tables  ProfileID * EventID / out=CEDRS_DupChk(where=(count>1));

* Print list of duplicate records;
   PROC print data=CEDRS_DupChk; 
      id EventID;
run;

* Print record for specific Profile ID (or subsitute or add Event ID);
   PROC print data= CEDRS_DupChk;
      where ProfileID='1234567';
      id ProfileID; 
      var EventID  LastName FirstName ReportedDate ;
run;

/*__________________________________________________________________________________*
 | FINDINGS:
 | No duplicate records with EventID (and therefore with ProfileID - EventID).
 *__________________________________________________________________________________*/



***  2. Age_at_Reported values  ***;
***-----------------------------***;

   PROC univariate data= COVID.CEDRS_view ;
      var Age_at_Reported ;
run;

* 2.1) Records where Age_at_Reported > 105;
   PROC print data= COVID.CEDRS_view;
      where Age_at_Reported > 105 ;
      id ProfileID;
      var EventID Age_Group Age_at_Reported ;
run;

/*___________________________________________*
 | FINDINGS: N=23 obs with age > 105.        |
 | FIX: set age to missing for when age>109  |
 *___________________________________________*/



***  3. Completeness of date variables (for use to count cases)  ***;
***---------------------------------------------------------------***;

   PROC means data= COVID.CEDRS_view n nmiss;
      var ReportedDate   CollectionDate   OnsetDate   OnsetDate_proxy_dist ;
run;

/*__________________________________________________________________*
 | FINDINGS:                                                        |
 |   Onsetdate is sparse.                                           |
 |   Onsetdate_proxy_dist and onsetdate_proxy are different dates.  |
 |   RS says to use Onsetdate_proxy_dist.                           |
 | FIX: Drop Onsetdate_proxy variabe (in Read.CEDRS.sas)            |
 *__________________________________________________________________*/



***  4. Check ICU variable  ***;
***-------------------------***;

   PROC freq data= COVID.CEDRS_view ;
      tables ICU ;
run;

/*____________________________________________________________________________*
 | FINDINGS:                                                                  |
 |   95% have value "Unknown". Q. How does this differ from "no"?             |
 |   per BK, "Unknown" = 'NO';                                                |
 |                                                                            |
 | FIX: create and apply ICU_fmt that combines "Unknown" with "NO" values.    |
 *____________________________________________________________________________*/



***  5. Check County variable  ***;
***----------------------------***;

* Proc format to define valid Colorado county names;
   PROC format;   value $CntyChk
   'ADAMS'        = 'ADAMS'
   'ALAMOSA'      = 'ALAMOSA'
   'ARAPAHOE'     = 'ARAPAHOE'
   'ARCHULETA'    = 'ARCHULETA'
   'BACA'         = 'BACA'
   'BENT'         = 'BENT'
   'BOULDER'      = 'BOULDER'
   'BROOMFIELD'   = 'BROOMFIELD'
   'CHAFFEE'      = 'CHAFFEE'
   'CHEYENNE'     = 'CHEYENNE'
   'CLEAR CREEK'  = 'CLEAR CREEK'
   'CONEJOS'      = 'CONEJOS'
   'COSTILLA'     = 'COSTILLA'
   'CROWLEY'      = 'CROWLEY'
   'CUSTER'       = 'CUSTER'
   'DELTA'        = 'DELTA'
   'DENVER'       = 'DENVER'
   'DOLORES'      = 'DOLORES'
   'DOUGLAS'      = 'DOUGLAS'
   'EAGLE'        = 'EAGLE'
   'ELBERT'       = 'ELBERT'
   'EL PASO'      = 'EL PASO'
   'FREMONT'      = 'FREMONT'
   'GARFIELD'     = 'GARFIELD'
   'GILPIN'       = 'GILPIN'
   'GRAND'        = 'GRAND'
   'GUNNISON'     = 'GUNNISON'
   'HINSDALE'     = 'HINSDALE'
   'HUERFANO'     = 'HUERFANO'
   'JACKSON'      = 'JACKSON'
   'JEFFERSON'    = 'JEFFERSON'
   'KIOWA'        = 'KIOWA'
   'KIT CARSON'   = 'KIT CARSON'
   'LAKE'         = 'LAKE'
   'LA PLATA'     = 'LA PLATA'
   'LARIMER'      = 'LARIMER'
   'LAS ANIMAS'   = 'LAS ANIMAS'
   'LINCOLN'      = 'LINCOLN'
   'LOGAN'        = 'LOGAN'
   'MESA'         = 'MESA'
   'MINERAL'      = 'MINERAL'
   'MOFFAT'       = 'MOFFAT'
   'MONTEZUMA'    = 'MONTEZUMA'
   'MONTROSE'     = 'MONTROSE'
   'MORGAN'       = 'MORGAN'
   'OTERO'        = 'OTERO'
   'OURAY'        = 'OURAY'
   'PARK'         = 'PARK'
   'PHILLIPS'     = 'PHILLIPS'
   'PITKIN'       = 'PITKIN'
   'PROWERS'      = 'PROWERS'
   'PUEBLO'       = 'PUEBLO'
   'RIO BLANCO'   = 'RIO BLANCO'
   'RIO GRANDE'   = 'RIO GRANDE'
   'ROUTT'        = 'ROUTT'
   'SAGUACHE'     = 'SAGUACHE'
   'SAN JUAN'     = 'SAN JUAN'
   'SAN MIGUEL'   = 'SAN MIGUEL'
   'SEDGWICK'     = 'SEDGWICK'
   'SUMMIT'       = 'SUMMIT'
   'TELLER'       = 'TELLER'
   'WASHINGTON'   = 'WASHINGTON'
   'WELD'         = 'WELD'
   'YUMA'         = 'YUMA'
   other = 'BAD COUNTY NAME';
run;

* Count of records by formatted County name;
   PROC freq data= COVID.CEDRS_view ;
      tables  CountyAssigned;
      format CountyAssigned $CntyChk. ;
run;

* Print records where County name is NOT valid;
DATA ChkCounty; set COVID.CEDRS_view;
   keep ProfileID EventID CountyAssigned ChkCounty;
   ChkCounty = put(CountyAssigned, $CntyChk.);
   PROC print data= ChkCounty; 
      where ChkCounty='BAD COUNTY NAME';
run;

/*_________________________________________________________*
 | FINDINGS:  n=71 records where County = "INTERNATIONAL"  | 
 | FIX: exclude these records                              |
 *_________________________________________________________*/



***  6. Missing ID variables and format of ID variables  ***;
***------------------------------------------------------***;

DATA ChkKeys; set COVID.CEDRS_view;
   keep ProfileID EventID Reinfection CountyAssigned ReportedDate ProfileID_length EventID_length ;
   ProfileID_length = length(ProfileID);
   EventID_length   = length(EventID);
run;
proc contents data=ChkKeys; run;
   PROC freq data= ChkKeys; 
      tables ProfileID_length  EventID_length ;
run;

/*______________________________________________________________________________________________________*
 | NOTE: a length=1 indicates a missing / blank value.
 | FINDINGS:
 |  No records have missing values for ProfileID or EventID (i.e. len=1).
 |  EventID values are either 7 digits long (30% of records) or 6 digits long (70%).                     |
 |  n=2593 records with 9 digit ProfileID values. All have ".1" appended to matching 7 digit ProfileID.  | 
 *_______________________________________________________________________________________________________*/


**  6.1)  Print records where ProfileID has length = 9  **;
   PROC print data= ChkKeys ;
      where ProfileID_length=9  ;
      id ProfileID;
run;
   PROC freq data= COVID.CEDRS_view ;  tables  Reinfection;  run;

/*____________________________________________________*
 | FINDINGS:                                          |
 | All records with ".1" are reinfection events.      |
 | Q. Why not have seperate EventID for these?        |
 | BUT not all records where reinfection=1 have ".1"  |
 *____________________________________________________*/


* Print records with missing ProfileID or EventID;
   PROC print data= ChkKeys ;
      where ProfileID_length=1  OR  EventID_length=1 ;
run;

   PROC print data= COVID.CEDRS_view ;
      where ProfileID=''  OR  EventID='';
/*      var ProfileID EventID ReportedDate ;*/
run;

/*___________________________________________________________*
 | FINDINGS:  NO records have missing ProfileID or EventID.  |
 *___________________________________________________________*/



***  7. Missing ID variables  ***;
***---------------------------***;

* List of ID values for all records;
   PROC freq data= COVID.CEDRS_view ;
     tables ProfileID * EventID /list missing missprint;
run;








