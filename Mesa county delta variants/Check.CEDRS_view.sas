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

** Contact variables **;
options ps=50 ls=150 ;
   proc print data= COVID.CEDRS_view;
      ID ProfileID ;
      var homeless address1 address2 addressactual address_city address_cityactual address_zipcode address_zipactual address_zip4actual 
          address_latitude address_longitude address_tract2000 address_state;
run;

 /*
 / FINDINGS:                                                                 
   / The variables with "actual" suffix are mostly missing.
   / The other contact variables are complete.
   / There are multiple ID's with same address but no "household" variable.
   / State is 2 character FIPS code
   / DROP: addressactual  address_cityactual  address_zipactual  address_zip4actual
*/


** Date variables **;
options ps=65 ls=110 ;
   proc print data= COVID.CEDRS_view;
      ID ID ;
      var onsetdate  onsetdate_proxy_dist  onsetdate_proxy 
          reporteddate  collectiondate  deathdate
          vax_utd  earliest_collectiondate  data_pulled_as_of ;
run;

 /*
 / FINDINGS:                                                                 
   / All date fields are character variables. Q. Convert to date variables?
   / Onsetdate is sparse whereas onsetdate_proxy_dist and onsetdate_proxy are complete
   / Onsetdate_proxy_dist and onsetdate_proxy are different dates. 
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
