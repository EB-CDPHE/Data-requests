/**********************************************************************************************
PROGRAM: RFI.DeltaVOC_in_Mesa.sas
AUTHOR:  Eric Bush
CREATED: June 9, 2021
MODIFIED:	
PURPOSE:	Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		COVID.CEDRS_view   work.B6172_edit
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

/*________________________________________________________________________________________*
 | Programs to run prior to this code:
 | 1. Pull data from CEDRS using READ.CEDRS_view.  Creates COVID.CEDRS_view 
 | 2. Pull data on variants using READ.B6172.  Creates work.B6172_edit
 | 3. Mesa.formats.sas program
 *________________________________________________________________________________________*/

%inc 'C:\Users\eabush\Documents\GitHub\Data-requests\Mesa county delta variants\Mesa.formats';

/*________________________________________________________________________________________*
 | Table of contents for RFI code:
 | 1. PROC contents for 
 |    a. COVID.CEDRS_view dataset from dphe144
 |    b. work.B6172_edit dataset from dphe66
 |
 | 2. Demographics for confirmed and probable cases
 | --> filtered dataset = NOT MESA county AND >Apr 5, 2021 (work.Not_Mesa144)
 |    a) Time reference period
 |    b) Number of cases (confirmed or probable)
 |    c) Age statistics on cases (confirmed or probable)
 |    d) Demographics for cases (confirmed or probable)
 |
 | 3. Demographics for confirmed and probable cases
 | --> filtered dataset = ONLY MESA county AND >Apr 5, 2021 (work.Mesa144)
 |    a) Time reference period
 |    b) Number of cases (confirmed or probable)
 |    c) Age statistics on cases (confirmed or probable)
 |    d) Demographics for cases (confirmed or probable)
 |
 | 4. Merge demographic variables from CEDRS with B6172 variant data
 |
 | 5. Demographics for B.1.617.2 (Delta) variants
 | --> filtered dataset = NOT MESA county (work.Not_Mesa_B16172)
 |    a) Time reference period
 |    b) Number of cases (with Delta variant)
 |    c) Age statistics on cases (with Delta variant)
 |    d) Demographics for cases (with Delta variant)
 |
 | 5. Demographics for B.1.617.2 (Delta) variants
 | --> filtered dataset = ONLY MESA county (work.Mesa_B16172)
 |    a) Time reference period
 |    b) Number of cases (with Delta variant)
 |    c) Age statistics on cases (with Delta variant)
 |    d) Demographics for cases (with Delta variant)
 *________________________________________________________________________________________*/


options pageno=1;

* 1. Contents of datasets to query for RFI *;
   PROC contents data=COVID.CEDRS_view varnum;
      title1 'dphe144 - CEDRS_view (a copy of CEDRS_dashboard_constrained)';
run;

 PROC contents data= B6172_edit varnum ;
      title1 'dphe66 - SQL join of several data tables';
run;


*** 2. Demographics for Colorado Cases (minus Mesa cases) ***;
***_______________________________________________________***;

options pageno=1;
title2 'County = ALL but Mesa';

DATA Not_Mesa144 ;  
   set COVID.CEDRS_view;;
   if CountyAssigned ^= 'MESA'  AND ReportedDate ge '05APR21'd ;
   if Age_at_Reported > 105 then Age_at_Reported = . ;
run;

** a) Time reference period **;
   proc sort data= Not_Mesa144 out=Not_Mesa144_by_date(keep=ReportedDate );  by ReportedDate;
data daterange1; set Not_Mesa144_by_date  END=eof;
   if _n_ = 1 then do; TimeRef='Earliest'; output; end;
   if eof then do;  TimeRef='Latest'; output; end;
run;
proc print data=daterange1; 
   id TimeRef; 
   format ReportedDate mmddyy10. ;
run;

** b) Number of cases (confirmed or probable) **;
   PROC means data= Not_Mesa144  n  nmiss min max   maxdec=0;
      var ReportedDate  Hospitalized  Reinfection  Breakthrough      ;
      format ReportedDate  yymmdd10. ;
run;

** c) Age statistics on cases (confirmed or probable) **;
   PROC means data= Not_Mesa144  n  nmiss min p1 p5 p10 mean median p90 p95 p99 max   maxdec=1;
      var  Age_at_Reported ;
      format ReportedDate  yymmdd10. ;
run;
   PROC univariate data= Not_Mesa144  ;
      var Age_at_Reported ;
      id profileid;
run;

** List of cases/records in Colorado (minus Mesa county) with ages >100 **;
/*proc print data=Not_Mesa144; */
/*   where Age_at_Reported>100;*/
/*   id ProfileID;*/
/*   var EventID Age_at_Reported age_group liveininstitution countyassigned outcome casestatus gender reinfection hospitalized outbreak_associated breakthrough deathdate vax_utd;*/
/*run;*/
/* Cases with age of 121, 936, 1021 which are clearly errors. Solution: If age>105 then age=.  */

** d) Demographics for cases (confirmed or probable) **;
   PROC freq data= Not_Mesa144;
      tables  Gender  Hospitalized  Outcome  Reinfection  Breakthrough ;
      format  Gender $genderfmt.  Outcome $Outcome_2cat.;
run;



*** 3. Demographics for Mesa County Cases ***;
***_______________________________________***;

options pageno=1;
title2 'County = MESA';

DATA Mesa144 ;  
   set COVID.CEDRS_view;
   if CountyAssigned = 'MESA'  AND ReportedDate ge '05APR21'd ;
run;


** a) Time reference period **;
   proc sort data= Mesa144 out=Mesa144_by_date(keep=ReportedDate );  by ReportedDate;
data daterange2; set Mesa144_by_date  END=eof;
   if _n_ = 1 then do; TimeRef='Earliest'; output; end;
   if eof then do;  TimeRef='Latest'; output; end;
run;
proc print data=daterange2; 
   id TimeRef; 
   format ReportedDate mmddyy10. ;
run;

** b) Number of cases (confirmed or probable) **;
   PROC means data= Mesa144  n  nmiss min max   maxdec=1;
      var ReportedDate  Hospitalized  Reinfection  Breakthrough      ;
      format ReportedDate  yymmdd10. ;
run;

** c) Age statistics on cases (confirmed or probable) **;
   PROC means data= Mesa144  n  nmiss min p1 p5 p10 mean median p90 p95 p99 max   maxdec=1;
      var  Age_at_Reported ;
      format ReportedDate  yymmdd10. ;
run;
   PROC univariate data= Mesa144 ;
      var Age_at_Reported ;
      id profileid;
run;

** d) Demographics for cases (confirmed or probable) **;
   PROC freq data= Mesa144;
      tables  Gender  Hospitalized  Outcome  Reinfection  Breakthrough ;
      format  Gender $genderfmt.  Outcome $Outcome_2cat. ;
run;


*** 4. Merge demographic variables from CEDRS with B6172 variant data ***;
***___________________________________________________________________***;

/*______________________________________________________________________________________________________*
 | Code below adds demographic variables from above CEDRS dataset to the B6172_edit dataset. 
 | B6172_edit dataset is from variant of concern (B.1.617.2) in Colorado. 
 | B6172_edit was created from SQL join supplied by Bre. See Read.B6172. 
 | Read.B6172 creates COVID.B6172 and then Check.B6172 creates B6172_edit. 
 | Merge demographic vars from CEDRS with B.1.617.2 variant data in B6172_edit. 
 *______________________________________________________________________________________________________*/

PROC sort data= COVID.CEDRS_view(keep= ProfileID EventID Hospitalized  Reinfection  Breakthrough Outcome)  
   out=CEDRSkey; 
   by ProfileID EventID;

PROC sort data= B6172_edit  out=B6172_key; by ProfileID EventID;
run;

DATA B6172_n_CEDRS;  merge CEDRSkey(in=C)  B6172_key(in=V);  
   by ProfileID EventID;
   if V ;
run;


*** 5. Demographics for Colorado (minus Mesa) cases with B.1.217.2 variant ***;
***________________________________________________________________________***;

options pageno=1;
title1 "Bre's SQL join --> denominator_ALL_B6172";
title2 'County = ALL but Mesa';
title3 'Variant = B.1.617.2 (Delta)';


DATA Not_Mesa_B16172 ;  set B6172_n_CEDRS ;
   if upcase(County) ^= 'MESA'  AND ReportedDate ge '05APR21'd ;
run;

** 2. Time reference period **;
   proc sort data= Not_Mesa_B16172 out=Not_Mesa_B16172_by_date(keep=ReportedDate );  by ReportedDate;
data daterange3; set Not_Mesa_B16172_by_date  END=eof;
   if _n_ = 1 then do; TimeRef='Earliest'; output; end;
   if eof then do;  TimeRef='Latest'; output; end;
run;
proc print data=daterange3; 
   id TimeRef; 
   format ReportedDate mmddyy10. ;
run;

** 3. Number of cases (confirmed or probable) with B.1.617.2 variant **;
   PROC means data= Not_Mesa_B16172  n  nmiss ;
      var ReportedDate  Hospitalized  Reinfection  Breakthrough    ;
      format ReportedDate  yymmdd10. ;
run;

** 4. Age statistics on cases (confirmed or probable) with B.1.617.2 variant **;
   PROC means data= Not_Mesa_B16172  n  nmiss min p1 p5 p10 mean median p90 p95 p99 max   maxdec=1;
      var  Age ;
run;
/*   PROC univariate data= Not_Mesa_B16172  freq  ;*/
/*      var Age ;*/
/*      id profileid;*/
/*run;*/

** 5. Demographics for cases (confirmed or probable) with B.1.617.2 variant **;
   PROC freq data= Not_Mesa_B16172;
      tables  Gender  Hospitalized  Outcome  Reinfection  Breakthrough  ;
      format  Gender $genderfmt.  Outcome $Outcome_2cat. ;
run;

   
*** 6. Demographics for Mesa county cases with B.1.217.2 variant ***;
***______________________________________________________________***;

options pageno=1;
title2 'County = Mesa';

DATA Mesa_B16172 ;  set B6172_n_CEDRS ;
   if upcase(County) = 'MESA';
   if outcome='' then outcome='Unknown';
run;

** 2. Time reference period **;
   proc sort data= Mesa_B16172 out=Mesa_B16172_by_date(keep=ReportedDate );  by ReportedDate;
data daterange4; set Mesa_B16172_by_date  END=eof;
   if _n_ = 1 then do; TimeRef='Earliest'; output; end;
   if eof then do;  TimeRef='Latest'; output; end;
run;
proc print data=daterange4; 
   id TimeRef; 
   format ReportedDate mmddyy10. ;
run;

** 3. Number of cases (confirmed or probable) with B.1.617.2 variant **;
   PROC means data= Mesa_B16172  n  nmiss ;
      var ReportedDate     ;
      format ReportedDate  yymmdd10. ;
run;

** 4. Age statistics on cases (confirmed or probable) with B.1.617.2 variant **;
   PROC means data= Mesa_B16172  n  nmiss min p1 p5 p10 mean median p90 p95 p99 max   maxdec=1;
      var  Age ;
run;

** 5. Demographics for cases (confirmed or probable) with B.1.617.2 variant **;
   PROC freq data= Mesa_B16172;
      tables  Gender   Hospitalized  Outcome  Reinfection  Breakthrough  ;
      format  Gender $genderfmt.  Outcome $Outcome_2cat.  ;
run;

