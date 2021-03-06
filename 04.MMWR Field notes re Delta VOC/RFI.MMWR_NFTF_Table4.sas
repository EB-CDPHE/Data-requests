/**********************************************************************************************
PROGRAM:  RFI.MMWR_NFTF_Table4.sas
AUTHOR:   Eric Bush
CREATED:  July 5, 2021
MODIFIED: 080221: redo table by new age groups per CDC AND redirect permanent datasets from J to C drive
          072221: redo table by age groups per CDC request	
PURPOSE:	 Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:	 COVID.CEDRS_view   COVID.County_Population  COVID.COPHS_fix
OUTPUT:	 MMWR_cases   MMWR_ICU
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'C:\Users\eabush\Documents\CDPHE\Requests\data'; run;

/*_____________________________________________________________________________________________*
 | Programs to run prior to this code:
 | 1. Pull data from CEDRS using Access.CEDRS_view.  Creates CEDRS_view_read
 | 2. Make data edits to CEDRS_view using FIX.CEDRS_view.  Creates COVID.CEDRS_view_fix
 |    a. Pull data from Events using Access.zDSI_Events to get Age.  Creates zDSI_Events.read
 |    b. Make data edits using Fix.zDSI_Events to create Age_in_Years. Creates zDSI_Events.fix
 | 3. Pull data on variants using Access.B6172.  Creates B6172_read
 | 4. Make data edits to B6172_read using Fix.B6172. Creates B6172_fix.
 | 5. MMWR.formats.sas creates formats for this program.
 | 6. Pull data from COPHS using Access.COPHS.   Creates COPHS_read
 | 7. Make data edits to COPHS using FIX.COPHS.  Creates COVID.COPHS_fix
 *_____________________________________________________________________________________________*/


***  Can run the files directly by submitting these statements:  ***;
***--------------------------------------------------------------***;

*  1. Submit Access.CEDRS_view  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Access.CEDRS_view.sas';

*  2. Submit Access.zDSI_Events  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Access.zDSI_Events.sas';

*  3. Submit Fix.zDSI_Events  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Fix.zDSI_Events.sas';

*  4. Submit Fix.CEDRS_view  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Fix.CEDRS_view.sas';

*  5. Submit MMWR.formats.sas  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\MMWR.formats.sas';

*  6. Submit Access.COPHS  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Access.COPHS.sas';

*  7. Submit Fix.COPHS  *;
%include 'C:\Users\eabush\Documents\GitHub\Data-requests\Fix.COPHS.sas';


/*______________________________________________________________________________________________________________*
 | Table of contents for RFI code:
 | 1. PROC contents for input datasets: 
 |    a. CEDRS_view_fix dataset from dphe144
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
   drop ICU;
run;


 ** 3. Contents of dataset to query for RFI **;
PROC contents data= MMWR_cases  ;
      title1 'COVID.CEDRS_view obs between April 20 - June 6';
run;


%include 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\MMWR.formats.sas';


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
COUNTY	AGE	  TOTAL
ROC	 0 to 17	   1226513
ROC	 18 to 64   3566367
ROC	 65 to 109   816168
ROC	 All_Ages   5609048
MESA	 0 to 17	     33866
MESA	 18 to 64 	  90471
MESA	 65 to 109    30594
MESA	 All_Ages	 154931
______________________________*/

* Use total population and age group population together to create County population by age for Mesa and ROC;
DATA CountyPopulation;
   input County $  Yrs0_17  Yrs18_64  Yrs65plus  TotalPop;
   datalines;
   MESA 33866   90471   30594  154931 
   ROC  1226513 3566367 816168 5609048
   ;
run;
DATA CountyPop; set CountyPopulation;
   Label
      Yrs0_17   = 'Population for 0-17 year olds'
      Yrs18_64  = 'Population for 18-64 year olds' 
      Yrs65plus = 'Population for 65 and older' ;
   format County $4.;
RUN;

   PROC contents data=CountyPop; run;
   PROC print data= CountyPop; id County; run;


***  5. Case count, Population total and calculation of case rates per 100K - by region and Age group  ***;
***____________________________________________________________________________________________________***;

** Cases in 0-17 yo by region **;
**----------------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
      where 0 le Age_Years < 18;
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

Data YrGrp1_Pop; length County $13; set CountyPop(rename=(Yrs0_17=Population));
   keep County Population;
/*   proc contents data= YrGrp1_Pop; run;*/
/*   proc print data=YrGrp1_Pop; id County; */
run;

** Calculation of case rate per 100K for 0-17 yo by region **;
   proc sort data= YrGrp1_Cases; by County; run;
   proc sort data=YrGrp1_Pop ; by County; run;
Data YrGrp1_CaseRate; merge YrGrp1_Cases  YrGrp1_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='0-17 yo';
run;
/*   PROC print data= YrGrp1_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


** Cases in 18-64 yo by region **;
**----------------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
      where 18 le Age_Years < 65;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=Y2_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
Data YrGrp2_Cases; set Y2_Cases(rename=(County=tmp_County));
   County = put(tmp_County,$MesaFmt.);
   drop tmp_County;
run;

Data YrGrp2_Pop; length County $13; set CountyPop(rename=(Yrs18_64=Population));
   keep County Population;
run;

** Calculation of case rate per 100K for 18-64 yo by region **;
   proc sort data= YrGrp2_Cases; by County; run;
   proc sort data=YrGrp2_Pop ; by County; run;
Data YrGrp2_CaseRate; merge YrGrp2_Cases  YrGrp2_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='18-64 yo';
run;
/*   PROC print data= YrGrp2_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


** Cases in 65+ yo by region **;
**----------------------------**;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  nway noprint ;
      where 65 le Age_Years ;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=Y3_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
Data YrGrp3_Cases; set Y3_Cases(rename=(County=tmp_County));
   County = put(tmp_County,$MesaFmt.);
   drop tmp_County;
run;

Data YrGrp3_Pop; length County $13; set CountyPop(rename=(Yrs65plus=Population));
   keep County Population;
run;

** Calculation of case rate per 100K for 65+ yo by region **;
   proc sort data= YrGrp3_Cases; by County; run;
   proc sort data=YrGrp3_Pop ; by County; run;
Data YrGrp3_CaseRate; merge YrGrp3_Cases  YrGrp3_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='65+ yo';
run;
/*   PROC print data= YrGrp3_CaseRate;  id county;   format CasesPer100K 4.0;  run;*/


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
   set   YrGrp1_CaseRate   YrGrp2_CaseRate   YrGrp3_CaseRate   All_CaseRate   ;
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
      format   County $MesaFmt.   Age_Years Age3cat.  hospitalized HospFmt. ;
      title1 'Admission to hospital among cases';
      title2 'data= MMWR_cases';
run;



***   8. Admission to ICU among hospitalized cases per COPHS   ***;
***____________________________________________________________***;

   PROC contents data= COVID.COPHS      varnum;  run;
   PROC contents data= COVID.COPHS_fix  varnum;  run;

** RUN the Key_merge.COPHS.CEDRS.sas program to link COPHS ICU admission to MMWRcases dataset. **;

%include 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\Key_Merge.COPHS.CEDRS.sas';


   PROC freq data= MMWR_cases ;
      where hospitalized =1  AND  ICU=1;
/*      tables  County  Age_Years hospitalized ICU /missing missprint;*/
      tables             County * ICU / nocol nopercent  ;
      tables Age_Years * County * ICU / nocol nopercent  ;
      format   County $MesaFmt.   Age_Years Age3cat.  hospitalized HospFmt. ;
      title1 'Admission to ICU among hospitalized cases';
      title2 'data= MMWR_ICU';
run;



***   9. Case fatality ratio   ***;
***____________________________***;

   PROC freq data= MMWR_cases ;
/*      tables  County  Age_Years outcome;*/
      tables             County * outcome / nocol chisq ;
      tables Age_Years * County * outcome / nocol chisq ;
      format   County $MesaFmt.   Age_Years Age3cat.   outcome $Outcome_2cat.   ;
      title1 'Case fatality ratio';
      title2 'data= MMWR_cases';
run;



***   10. Case fatality ratio among those hospitalized   ***;
***______________________________________________________***;

   PROC freq data= MMWR_cases ;
      where hospitalized=1;
/*      tables  hospitalized;*/
      tables             County * outcome / nocol chisq ;
      tables Age_Years * County * outcome / nocol chisq ;
      format   County $MesaFmt.   Age_Years Age3cat.   outcome $Outcome_2cat.  hospitalized HospFmt. ;
      title1 'Case fatality ratio among hospitalized';
      title2 'data= MMWR_cases ';
run;



