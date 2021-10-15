/**********************************************************************************************
PROGRAM: Check.CEDRS_view
AUTHOR:  Eric Bush
CREATED: June 8, 2021
MODIFIED:	063021:  updated to be consistent with template codes
PURPOSE:	Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		COVID.CEDRS_view
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COVID.CEDRS_view varnum; run;

** Admin variables **;

   proc print data= COVID.CEDRS_view;
     var ID ProfileID EventID ;
run;

   proc freq data= COVID.CEDRS_view;
     tables ID * ProfileID * EventID /list missing missprint;
run;

** Check for duplicate records **;

* 1. Identify Profile IDs with duplicate records *;
   PROC FREQ data= COVID.CEDRS_view noprint;  
      tables  EventID / out=CEDRS_DupChk(where=(count>1));
   PROC print data=CEDRS_DupChk; 
      id EventID;
run;

/*__________________________________________________________________________________*
 | FINDINGS:
 | No duplicate records with EventID (and therefore with ProfileID - EventID).
 *__________________________________________________________________________________*/


** Contact variables **;
* COMMENT out since all of the address: variables have been dropped;
options ps=50 ls=150 ;
/*   proc print data= COVID.CEDRS_view;*/
/*      ID ProfileID ;*/
/*      var homeless address1 address2 addressactual address_city address_cityactual address_zipcode address_zipactual address_zip4actual */
/*          address_latitude address_longitude address_tract2000 address_state;*/ 
/*run;*/

 /*
 / FINDINGS:                                                                 
   / The variables with "actual" suffix are mostly missing.
   / The other contact variables are complete.
   / There are multiple ID's with same address but no "household" variable.
   / State is 2 character FIPS code
   / DROP: addressactual  address_cityactual  address_zipactual  address_zip4actual
*/

** Check Age_at_Reported variable **;
   PROC univariate data= COVID.CEDRS_view ;
      var Age_at_Reported ;
run;
   PROC print data= COVID.CEDRS_view;
      where Age_at_Reported > 105 ;
      id ProfileID;
      var EventID Age_Group Age_at_Reported ;
run;
/*____________________________________________________________________*
 | FINDINGS:    
 | N=23 obs with age > 105. FIX: set age to missing for when age>109
 *____________________________________________________________________*/

** Completeness of date variables (for use to count cases) **;
   PROC means data= COVID.CEDRS_view n nmiss;
      var ReportedDate   CollectionDate   OnsetDate   OnsetDate_proxy_dist ;
run;


** Check ICU variable **;
   PROC freq data= COVID.CEDRS_view ;
      tables ICU ;
run;
/*____________________________________________________________________*
 | FINDINGS:    
 | 95% have value "Unknown". Q. How does this differ from "no"? 
 *____________________________________________________________________*/


** Check County variable **;
** Must run proc format below first **;
   PROC freq data= COVID.CEDRS_view ;
      tables  CountyAssigned;
      format CountyAssigned $CntyChk. ;
run;

data ChkCounty; set COVID.CEDRS_view;
   keep ProfileID EventID CountyAssigned ChkCounty;
   ChkCounty = put(CountyAssigned, $CntyChk.);
   proc print data= ChkCounty; 
      where ChkCounty='BAD COUNTY NAME';
run;
/*_________________________________________________*
 | FINDINGS:    
 | 71 records where County = "INTERNATIONAL". 
 | FIX: exclude these records
 *_________________________________________________*/


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



** Date variables **;
options ps=65 ls=110 ;
   proc print data= COVID.CEDRS_view;
      ID ID ;
      var onsetdate  onsetdate_proxy_dist   
          reporteddate  collectiondate  deathdate
          vax_utd  earliest_collectiondate  data_pulled_as_of ;
run;

 /*
 / FINDINGS:                                                                 
   / All date fields are character variables. Q. Convert to date variables?
   / Onsetdate is sparse whereas onsetdate_proxy_dist and onsetdate_proxy are complete
   / Onsetdate_proxy_dist and onsetdate_proxy are different dates. RS says to use Onsetdate_proxy_dist.
   / Q. HOW are these created?
 */

   proc freq data= COVID.CEDRS_view;   tables reporteddate; format reporteddate MONYY. ;  run;
   proc freq data= COVID.CEDRS_view;   tables reporteddate; format reporteddate DOWNAME. ; run;
   proc freq data= COVID.CEDRS_view;   tables reporteddate; format reporteddate WeekW5. ; run;


** Demographic variables **;
   proc print data= COVID.CEDRS_view;
      ID ID ;
      var age_group  age_at_reported  gender  homeless race ethnicity  single_race_ethnicity  single_race_ethnicity_with_ciis    ;
run;



   PROC print data= COVID.CEDRS_view;
      where ProfileID in ('1618760', '1646961', '1664420', '1678755');
      ID ProfileID ;
      var EventID   Gender   Age_at_Reported   Age_Group   Single_Race_Ethnicity   CountyAssigned   ReportedDate   ONsetDate 
          Hospitalized   ICU   Transmission_Type   LiveInInstitution   Outcome   CaseStatus   Homeless   Reinfection   Outbreak_Associated  Breakthrough
          Deathdate  Vax_Utd ;
run;
