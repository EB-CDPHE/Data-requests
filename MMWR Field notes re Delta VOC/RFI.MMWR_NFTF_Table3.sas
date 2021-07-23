/**********************************************************************************************
PROGRAM:  RFI.MMWR_NFTF_Table3.sas
AUTHOR:   Eric Bush
CREATED:  July 5, 2021
MODIFIED: 072221: redo table by age groups per CDC request	
PURPOSE:	 Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:	 COVID.CEDRS_view   COVID.B6172_fix   COVID.County_Population  COVID.COPHS_fix
OUTPUT:	 MMWR_cases   MMWR_ICU
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

/*________________________________________________________________________________________*
 | Programs to run prior to this code:
 | 1. Pull data from CEDRS using Access.CEDRS_view.  Creates CEDRS_view_read
 | 2. Make data edits to CEDRS_view using FIX.CEDRS_view.  Creates COVID.CEDRS_view_fix
 | 3. Pull data on variants using Access.B6172.  Creates B6172_read
 | 4. Make data edits to B6172_read using Fix.B6172. Creates B6172_fix.
 | 5. MMWR.formats.sas creates formats for this program.
 | 6. Pull data from COPHS using Access.COPHS.   Creates COPHS_read
 | 7. Make data edits to COPHS using FIX.COPHS.  Creates COVID.COPHS_fix
 | 8. Merge COPHS data on ICU admission to CEDRS data using Key_Merge.COPHS.CEDRS
 *________________________________________________________________________________________*/


***  Can run the files directly by submitting these statements:  ***;
***--------------------------------------------------------------***;

*  1. Submit Access.CEDRS_view  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Access.CEDRS_view.sas';

*  2. Submit Fix.CEDRS_view  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Fix.CEDRS_view.sas';

*  3. Submit Access.CEDRS_view  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Access.B6172.sas';

*  4. Submit Fix.B6172  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Fix.B6172.sas';

*  5. Submit MMWR.formats.sas  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\MMWR.formats.sas';

*  6. Submit Access.CEDRS_view  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Access.COPHS.sas';

*  7. Submit Fix.CEDRS_view  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Fix.COPHS.sas';

*  8. Submit MMWR.formats.sas  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\Key_Merge.COPHS.CEDRS.sas';


/*______________________________________________________________________________________________________________*
 | Table of contents for RFI code:
 | 1. PROC contents for input datasets: 
 |    a. CEDRS_view_fix dataset from dphe144
 |    b. B6172_fix dataset from dphe66
 |
 | 2. Create dataset for data request = MMWR_cases
 |    a. Modify dataset - imput missing collection dates
 |    b. Filter dataset - Colorado counties AND CollectionDate between April 20 - June 19, 2021
 | 3. PROC contents for output dataset for responding to data request:
 |    a. MMWR_cases
 | --> filtered dataset = Colorado counties AND CollectionDate between April 20 - June 19, 2021 (work.Not_Mesa144)
 | 4. Add county population data - total and by age groups
 |    a. PROC means to get total population by region (Mesa vs ROC)
 |    b. Input data from Rachel S. for population by age groups for each region
 |    c. PROC contents of CountyPop dataset
 | 5. Case count, Population total and calculation of case rates per 100K - by region and Age group
 |    a.  0-19 year olds
 |    b. 20-39 year olds
 |    c. 40-59 year olds
 |    d. 60-79 year olds
 |    e. 80+   year olds
 | 6. Hospitalizations by Age group and Region
 | 7. Admission to ICU among cases per COPHS by Age group and Region
 | 8. Case fatality ratio by Age group and Region
 | 9. Case fatality ratio among those hospitalized by Age group and Region
 *______________________________________________________________________________________________________________*/


options pageno=1;

** 1. Contents of input datasets to access **;
   PROC contents data=COVID.CEDRS_view_fix varnum;
      title1 'dphe144 - CEDRS_view (a copy of CEDRS_dashboard_constrained)';
run;

 PROC contents data= COVID.B6172_fix varnum ;
      title1 'dphe66 - SQL join of several data tables';
run;


** 2. Edit and filter datasets for defined target population **;
**-----------------------------------------------------------**;
** Impute missing collection dates  **;
DATA FixCollDate; set COVID.CEDRS_view_fix;
   if CollectionDate = . then CollectionDate=ReportedDate;
run;

** Filter CEDRS data for analysis to records with collection date between Apr 20 - Jun 6 **;       *<-- Input Time reference period ;
DATA MMWR_cases; set FixCollDate ;
   where '27APR21'd le CollectionDate le '06JUN21'd;                                             *<-- Input Time reference period ;
   if CountyAssigned = 'INTERNATIONAL' then delete;
   if Age_Years > 109 then Age_Years = .;
run;

 ** 3. Contents of dataset to query for RFI **;
PROC contents data= MMWR_cases  ;
      title1 'COVID.CEDRS_view obs between April 20 - June 6';
run;



***----------------------***;
***  SECTION 1 OF TABLE  ***;
***  All COVID cases     ***;
***----------------------***;

** 4. County Population data **;
   PROC contents data=COVID.County_Population; run;
/*   PROC print data= COVID.County_Population; id county; run;*/

* Get total population for Mesa and ROC;
proc means data= COVID.County_Population sum  maxdec=0;
var population;
class county;
format county $MesaFmt. ;
run;

* Rachel S used source webpage to get county population for Mesa and ROC by age groups;
*** source:  https://demography.dola.colorado.gov/population/data/sya-county/   ***;
/*___________________________
county	age	population
Mesa	0-19	38708
Mesa	20-39	38934
Mesa	40-59	36129
Mesa	60-79	33061
Mesa	80+	8099
Other	0-19	1380924
Other	20-39	1646743
Other	40-59	1431094
Other	60-79	973995
Other	80+	176292
______________________________*/

* Use total population and age group population together to create County population by age for Mesa and ROC;
DATA CountyPopulation;
   input County $  Yrs0_19  Yrs20_39  Yrs40_59  Yrs60_79  Yrs80plus TotalPop;
   datalines;
   MESA 38708   38934    36129   33061  8099   154933
   ROC  1380924 1646743 1431094 973995 176292 5609043
   ;
run;
DATA CountyPop; set CountyPopulation;
   Label
      Yrs0_19    = 'Population for 0-19 year olds'
      Yrs20_39  = 'Population for 20-39 year olds' ;
   format County $4.;
RUN;

   PROC contents data=CountyPop; run;
   PROC print data= CountyPop; id County; run;


***  5. Case count, Population total and calculation of case rates per 100K - by region and Age group  ***;
***____________________________________________________________________________________________________***;

** Cases in 0-19 yo by region **;
**----------------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
      where 0 le Age_Years < 20;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=Y1_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
Data YrGrp1_Cases; set Y1_Cases(rename=(County=tmp_County));
   County = put(tmp_County,$MesaFmt.);
   drop tmp_County;
run;
/*   proc print data=YrGrp1_Cases ; id County; run;*/
/*   proc contents data=YrGrp1_Cases ;  run;*/

Data YrGrp1_Pop; length County $13; set CountyPop(rename=(Yrs0_19=Population));
   keep County Population;
/*   proc contents data= YrGrp1_Pop; run;*/
/*   proc print data=YrGrp1_Pop; id County; */
run;

** Calculation of case rate per 100K for 0-19 yo by region **;
   proc sort data= YrGrp1_Cases; by County; run;
   proc sort data=YrGrp1_Pop ; by County; run;
Data YrGrp1_CaseRate; merge YrGrp1_Cases  YrGrp1_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='0-19 yo';
run;
/*   PROC print data= YrGrp1_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


** Cases in 20-39 yo by region **;
**----------------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
      where 20 le Age_Years < 40;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=Y2_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
Data YrGrp2_Cases; set Y2_Cases(rename=(County=tmp_County));
   County = put(tmp_County,$MesaFmt.);
   drop tmp_County;
run;

Data YrGrp2_Pop; length County $13; set CountyPop(rename=(Yrs20_39=Population));
   keep County Population;
run;

** Calculation of case rate per 100K for 20-39 yo by region **;
   proc sort data= YrGrp2_Cases; by County; run;
   proc sort data=YrGrp2_Pop ; by County; run;
Data YrGrp2_CaseRate; merge YrGrp2_Cases  YrGrp2_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='20-39 yo';
run;
/*   PROC print data= YrGrp2_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


** Cases in 40-59 yo by region **;
**----------------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
      where 40 le Age_Years < 60;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=Y3_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
Data YrGrp3_Cases; set Y3_Cases(rename=(County=tmp_County));
   County = put(tmp_County,$MesaFmt.);
   drop tmp_County;
run;

Data YrGrp3_Pop; length County $13; set CountyPop(rename=(Yrs40_59=Population));
   keep County Population;
run;

** Calculation of case rate per 100K for 40-59 yo by region **;
   proc sort data= YrGrp3_Cases; by County; run;
   proc sort data=YrGrp3_Pop ; by County; run;
Data YrGrp3_CaseRate; merge YrGrp3_Cases  YrGrp3_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='40-59 yo';
run;
/*   PROC print data= YrGrp3_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


** Cases in 60-79 yo by region **;
**----------------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
      where 60 le Age_Years < 80;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=Y4_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
Data YrGrp4_Cases; set Y4_Cases(rename=(County=tmp_County));
   County = put(tmp_County,$MesaFmt.);
   drop tmp_County;
run;

Data YrGrp4_Pop; length County $13; set CountyPop(rename=(Yrs60_79=Population));
   keep County Population;
run;

** Calculation of case rate per 100K for 60-79 yo by region **;
   proc sort data= YrGrp4_Cases; by County; run;
   proc sort data=YrGrp4_Pop ; by County; run;
Data YrGrp4_CaseRate; merge YrGrp4_Cases  YrGrp4_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='60-79 yo';
run;
/*   PROC print data= YrGrp4_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


** Cases in 80+ yo by region **;
**----------------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
      where 80 le Age_Years ;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=Y5_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
Data YrGrp5_Cases; set Y5_Cases(rename=(County=tmp_County));
   County = put(tmp_County,$MesaFmt.);
   drop tmp_County;
run;

Data YrGrp5_Pop; length County $13; set CountyPop(rename=(Yrs80plus=Population));
   keep County Population;
run;

** Calculation of case rate per 100K for 80+ yo by region **;
   proc sort data= YrGrp5_Cases; by County; run;
   proc sort data=YrGrp5_Pop ; by County; run;
Data YrGrp5_CaseRate; merge YrGrp5_Cases  YrGrp5_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='80+ yo';
run;
/*   PROC print data= YrGrp5_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


** Total Cases by region **;
**-----------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
/*      where 80 le Age_Years ;*/
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=All_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
Data All_Cases; set All_Cases(rename=(County=tmp_County));
   County = put(tmp_County,$MesaFmt.);
   drop tmp_County;
run;

Data All_Pop; length County $13; set CountyPop(rename=(TotalPop=Population));
   keep County Population;
run;

** Calculation of case rate per 100K for 80+ yo by region **;
   proc sort data= All_Cases; by County; run;
   proc sort data=All_Pop ; by County; run;
Data All_CaseRate; merge All_Cases  All_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='ALL';
run;
/*   PROC print data= All_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


** Put Case counts, pop totals, and Case rates for all age groups together **;
**-------------------------------------------------------------------------**;
Data CaseRate100K_temp; 
   set   YrGrp1_CaseRate   YrGrp2_CaseRate   YrGrp3_CaseRate   YrGrp4_CaseRate   YrGrp5_CaseRate   All_CaseRate   ;
   format CaseCounts Population comma11.0   CasesPer100K 5.0 ;
   proc sort data= CaseRate100K_temp  out= CaseRate100K ;  by county;
   PROC print data= CaseRate100K ;  id County; by County;
      var Age_Group CaseCounts Population CasesPer100K;
      title1 'Case rate per 100K';
      title2 'data= MMWR_cases';
run;



***  6. Hospitalizations by Age group and Region  ***;
***_______________________________________________***;

   PROC freq data= MMWR_cases ;
/*      tables  County  Age_Years hospitalized;*/
      tables             County  * hospitalized / nocol chisq ;
      tables Age_Years * County  * hospitalized / nocol chisq ;
      format   County $MesaFmt.   Age_Years Age5cat.  hospitalized HospFmt. ;
      title1 'Admission to hospital among cases';
      title2 'data= MMWR_cases';
run;



***   7. Admission to ICU among cases per COPHS   ***;
***_______________________________________________***;

   PROC contents data= COVID.COPHS      varnum;  run;
   PROC contents data= COVID.COPHS_fix  varnum;  run;

/*_____________________________________________________________________________________________*
 | FINDINGS:    
 | First, ID variable is MR_number. There is no ProfileID or EventID
 | If can't merge to CEDRS then how do you calculate "admission to ICU among cases"?
 *_____________________________________________________________________________________________*/


** RUN the Key_merge.COPHS.CEDRS.sas program to link COPHS ICU admission to MMWRcases dataset. **;

   proc freq data=MMWR_ICU ; tables ICU ICU_Admission; run;
   PROC means data= MMWR_ICU  n nmiss ;  var ICU_Admission hospitalized ICU; run;

   PROC freq data= MMWR_ICU ;
/*      tables  County  Age_Years hospitalized ICU;*/
      tables             County * ICU / nocol chisq ;
      tables Age_Years * County * ICU / nocol chisq ;
      format   County $MesaFmt.   Age_Years Age5cat. ;* hospitalized HospFmt. ;
      title1 'Admission to ICU among hospitalized cases';
      title2 'data= MMWR_ICU';
run;



**   8. Case fatality ratio   **;

   PROC freq data= MMWR_cases ;
/*      tables  County  Age_Years outcome;*/
      tables             County * outcome / nocol chisq ;
      tables Age_Years * County * outcome / nocol chisq ;
      format   County $MesaFmt.   Age_Years Age5cat.   outcome $Outcome_2cat.   ;
      title1 'Case fatality ratio';
      title2 'data= MMWR_cases';
run;



**   9. Case fatality ratio among those hospitalized   **;

   PROC freq data= MMWR_cases ;
      where hospitalized=1;
/*      tables  hospitalized;*/
      tables             County * outcome / nocol chisq ;
      tables Age_Years * County * outcome / nocol chisq ;
      format   County $MesaFmt.   Age_Years Age5cat.   outcome $Outcome_2cat.  hospitalized HospFmt. ;
      title1 'Case fatality ratio among hospitalized';
      title2 'data= MMWR_cases ';
run;



