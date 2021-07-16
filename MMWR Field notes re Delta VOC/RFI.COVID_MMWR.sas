/**********************************************************************************************
PROGRAM: RFI.COVID_MMWR.sas
AUTHOR:  Eric Bush
CREATED: July 5, 2021
MODIFIED:	
PURPOSE:	Generate estimates for new / revised table in MMWR Field Notes draft
INPUT:		COVID.CEDRS_view_fix   COVID.County_Population   
OUTPUT:		MMWR_cases   MMWR_ICU
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

/*________________________________________________________________________________________*
 | Programs to run prior to this code:
 | 1. Pull data from CEDRS using READ.CEDRS_view.  Creates COVID.CEDRS_view 
 | 2. Add new data checks (if needed) to CHECK.CEDRS_view.
 | 3. Add new data edits and run FIX.CEDRS_view. Creates COVID.CEDDRS_view.fix
 | 4. MMWR.formats.sas creates formats for this program.
 *________________________________________________________________________________________*/

%inc 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\MMWR.formats.sas';

/*______________________________________________________________________________________________________________*
 | Table of contents for RFI code:
 | 1. PROC contents for input datasets: 
 |    a. COVID.CEDRS_view_fix dataset from dphe144
 |    b. COVID.County_Population dataset from dphe66
 | 2. PROC contents for main dataset for estimation:  MMWR_Cases
 | --> filtered dataset = County NOT "International" AND  ReportedDate between April 20 - June 6, 2021 
 | 3. Demographics for confirmed and probable cases
 *______________________________________________________________________________________________________________*/


options pageno=1;

** 1. Contents of datasets to query for RFI **;
   PROC contents data=COVID.CEDRS_view_fix varnum;
      title1 'dphe144 - CEDRS_view_fix (a copy of CEDRS_dashboard_constrained)';
run;

/* PROC contents data= COVID.B6172_fix varnum ;*/
/*      title1 'dphe66 - SQL join of several data tables';*/
/*run;*/


*** 2.  Edit and filter datasets for defined target population  ***;
***-------------------------------------------------------------***;

** Impute missing collection dates  **;
DATA FixCollDate; set COVID.CEDRS_view_fix;
   if CollectionDate = . then CollectionDate=ReportedDate;
run;


** Filter CEDRS data for analysis to records with collection date between Apr 20 - Jun 6 **;       *<-- Input Time reference period ;
** Remove records for counties outside of Colorado **;

DATA MMWR_cases; set FixCollDate ;
   where '27APR21'd le CollectionDate le '06JUN21'd;                                             *<-- Input Time reference period ;
   if CountyAssigned = 'INTERNATIONAL' then delete;
   if Age_Years > 109 then Age_Years = .;
run;

 PROC contents data= MMWR_cases  ;
      title1 'CEDRS_view obs between April 20 - June 6';                                          *<-- Input Time reference period ;
run;



/*   proc sort data=COVID.County_Population  out=PopTot  ; by County;*/
/*   proc sort data=MMWR_cases  out=MMWR_cases_cnty_sort  ; by County;*/
/**/
/*DATA MMWR_cases_cnty; merge MMWR_cases_cnty_sort  PopTot;*/
/*   by County;*/
/*   Pop100k = population/100000;*/
/*   CountyGrp = put(County, $MesaFmt.);*/
/*run;*/
/*proc contents data=MMWR_cases_cnty varnum; run;*/
/*proc print data= MMWR_cases_cnty; */
/*var eventid county countygrp population pop100k ;*/
/*run;*/



***  3. Table estimates  ***;
***-----------------------**;

**  Row 1: Case rate per 100k by region (Mesa vs ROC)  **;

* Case count by region (Mesa vs ROC);
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway  ;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=CountyCases(drop=_FREQ_ _TYPE_) n=CaseCounts;
run;
/*proc print data=CountyCases ; id County; run;*/

* Population count by region;
   PROC means data= COVID.County_Population  sum nway maxdec=0  ; 
      class County ;
      var Population;
      format  County   $MesaFmt. ;
      output out=CountyPop(drop=_TYPE_ _FREQ_) sum=Population;
run;
/*   proc print data=CountyPop;   id County;   run;*/

* Calculation of case rate per 100K by region;
Data CaseRate; merge CountyCases  CountyPop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
run;

 * Print case rate per 100K by region;
   PROC print data= CaseRate;  id county;   format CasesPer100K 4.0;  run;
   PROC means data= CaseRate sum ;
      class County ;
      var CasesPer100K;
      format  County   $MesaFmt. ;
run;


**  Row 2: Hospitalizations among cases by region (Mesa vs ROC)  **;

   PROC freq data= MMWR_cases ;
      tables  Hospitalized;
      tables County  *  hospitalized / nocol chisq ;
      format   County $MesaFmt.    hospitalized HospFmt. ;
      title2 'Admission to hospital among cases';
      title3 'data= MMWR_cases';
run;


**  Row 3: ICU Admissions among hospitalized cases by County region  **;

** RUN the Key_merge.COPHS.CEDRS.sas program to link COPHS ICU admission to MMWRcases dataset. **;       * <-- NOTE;
%inc 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\Key_merge.COPHS.CEDRS.sas';

* Number cases hospitalized and admited to ICU;
/*   PROC freq data=MMWR_ICU ; tables ICU ICU_Admission; run;*/
   PROC means data= MMWR_ICU  n nmiss ;  
      var ICU_Admission hospitalized ICU; 
run;

* ICU Admissions among hospitalized cases;
   PROC freq data= MMWR_ICU ;
      where hospitalized=1;
      tables County  *  ICU / nocol chisq ;
      format   County $MesaFmt.    ;* hospitalized HospFmt. ;
      title2 'Admission to ICU among hospitalized cases';
      title3 'data= MMWR_ICU';
run;


**  Row 4: Case fatality ratio by County region  **;
   PROC freq data= MMWR_cases ;
      tables County  *  outcome / nocol chisq ;
      format   County $MesaFmt.    outcome $Outcome_2cat.   ;
      title2 'Case fatality ratio';
      title3 'data= MMWR_cases';
run;


**  Row 5: Case fatality ratio among hospitalized cases by County region **;
   PROC freq data= MMWR_cases ;
      where hospitalized=1;
      tables County  *  outcome / nocol chisq ;
      format   County $MesaFmt.    outcome $Outcome_2cat.   ;
      title2 'Case fatality ratio among hospitalized cases';
      title3 'data= MMWR_cases';
run;



***--------------------------------------***;
***  Numbers for text in draft document  ***;
***--------------------------------------***;

**  Merge demographic variables from CEDRS with B6172 variant data  **;
PROC sort data= MMWR_cases(keep= ProfileID EventID Hospitalized  Reinfection  Breakthrough Outcome CollectionDate Age_Years)  
   out=MMWR_sort; 
   by ProfileID EventID;

PROC sort data= COVID.B6172_fix  out=B6172_key; by ProfileID EventID;
run;

DATA B6172_n_MMWR;
   length County $ 11;
   merge MMWR_sort(in=M)  B6172_key(in=V);  
   by ProfileID EventID;
   if V=1 ;                      * <--- which if any is correct? ;

   if CollectionDate = . then CollectionDate=ReportedDate;
   format County $11.;
   tmp_county=County;
   County=upcase(tmp_county);
   drop tmp_county;
run;


**  Contents of MMWR_Cases data attached to Delta variant info  **;
   PROC contents data= B6172_n_MMWR varnum ; run;


 **  Count of cases with delta variant isolated  **;
  PROC means data= B6172_n_MMWR n nmiss ;
      var CollectionDate ReportedDate  ;
run;


**  Number of delta variants in Colorado and number (and %) in Mesa county as of June 6th  **;
   PROC freq data= B6172_n_MMWR ;
      where CollectionDate le '06JUN21'd ;
      tables County ; 
      format County $MesaFmt. ;
run;








