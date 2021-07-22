/**********************************************************************************************
PROGRAM:  RFI.MMWR_request3.sas
AUTHOR:   Eric Bush
CREATED:  July 5, 2021
MODIFIED: 072221: redo table by age groups per CDC request	
PURPOSE:	 Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		COVID.CEDRS_view   COVID.B6172_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

/*________________________________________________________________________________________*
 | Programs to run prior to this code:
 | 1. Pull data from CEDRS using Access.CEDRS_view.  Creates CEDRS_view_read
 | 2. Run FIX.CEDRS_view to make data edits to CEDRS_view.  Creates COVID.CEDRS_view_fix
 | 2. Pull data on variants using READ.B6172.sas.  Creates work.B6172_edit
 | 3. Make edits to B6172_read using Fix.B6172.sas. Creates B6172_fix.
 | 4. MMWR.formats.sas creates formats for this program.
 *________________________________________________________________________________________*/

%inc 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\MMWR.formats.sas';

/*______________________________________________________________________________________________________________*
 | Table of contents for RFI code:
 | 1. PROC contents for 
 |    a. COVID.CEDRS_view dataset from dphe144
 |    b. work.B6172_fix dataset from dphe66
 |
 | 2. Demographics for confirmed and probable cases
 | --> filtered dataset = MESA county AND ReportedDate between April 20 - June 19, 2021 (work.Not_Mesa144)
 *______________________________________________________________________________________________________________*/


options pageno=1;

** 1. Contents of datasets to query for RFI **;
   PROC contents data=COVID.CEDRS_view varnum;
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

 PROC contents data= MMWR_cases  ;
      title1 'COVID.CEDRS_view obs between April 20 - June 6';
run;



***----------------------***;
***  SECTION 1 OF TABLE  ***;
***  All COVID cases     ***;
***----------------------***;

** 3. County Population data **;
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



** 4. Count of Cases and sum of Population by County and Age  **;

** Case rate for 0-19 yo by region **;
**_________________________________**;

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
   PROC print data= YrGrp2_CaseRate;  id county;   format CasesPer100K 4.0;  run;


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
   PROC print data= YrGrp3_CaseRate;  id county;   format CasesPer100K 4.0;  run;


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
   PROC print data= YrGrp4_CaseRate;  id county;   format CasesPer100K 4.0;  run;


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
   PROC print data= YrGrp5_CaseRate;  id county;   format CasesPer100K 4.0;  run;


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
   PROC print data= All_CaseRate;  id county;   format CasesPer100K 4.0;  run;


** Put Case rate stats for all population groups together **;
**______________________________________________________________**;

Data CaseRate100K_temp; 
   set   YrGrp1_CaseRate   YrGrp2_CaseRate   YrGrp3_CaseRate   YrGrp4_CaseRate   YrGrp5_CaseRate   All_CaseRate   ;
   format CaseCounts Population comma11.0   CasesPer100K 5.0 ;
   proc sort data= CaseRate100K_temp  out= CaseRate100K ;  by county;
   PROC print data= CaseRate100K ;  id County; by County;
      var Age_Group CaseCounts Population CasesPer100K;
      title1 'Case rate per 100K';
      title2 'data= MMWR_cases';
run;



** 5. Hospitalizations by Age group and Region **;

   PROC freq data= MMWR_cases ;
      tables  County  Age_Years hospitalized;
      tables County  * Age_Years * hospitalized / nocol  ;
      format   County $MesaFmt.   Age_Years Age5cat.  hospitalized HospFmt. ;
      title1 'Admission to hospital among cases';
      title2 'data= MMWR_cases';
run;



**   6. Admission to ICU among cases   **;
/*--------------------------------------------------*
 | There are three sources of ICU data:
 | 1) CEDRS_view  (dphe144)
 | 2. Surveillance form  (dphe66)
 | 3. COPHS
 *--------------------------------------------------*/

**  1) ICU data from CEDRS_view   **;
   PROC freq data= COVID.CEDRS_view ;
      tables ReportedDate * ICU /nocol norow nopercent;
      format ReportedDate monyy.;
run;
/*_________________________________________________________________________________________*
 | FINDINGS:    
 | Can't use ICU variable from CEDRS_view because all values = 'Unknown' since July 2020!
 *_________________________________________________________________________________________*/


**  2) ICU data from Surveillance form   **;

   PROC freq data=SurvForm_read ; 
      /*tables ICU_SurvForm;*/
      tables CreatedDate  * ICU_SurvForm / nocol norow nopercent missing missprint;
      format CreatedDate  monyy. ;
run;
/*_____________________________________________________________________________________________*
 | FINDINGS:    
 | Can't use ICU variable from Surveillance Form because all values missing since June 2020!
 *_____________________________________________________________________________________________*/


**  3) ICU data from COPHS   **;

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
      tables County  * Age_Years * ICU / nocol  ;
      format   County $MesaFmt.   Age_Years AgeFmt. ;* hospitalized HospFmt. ;
      title1 'Admission to ICU among hospitalized cases';
      title2 'data= MMWR_ICU';
run;



**   7. Case fatality ratio   **;

   PROC freq data= MMWR_cases ;
/*      tables  County  Age_Years outcome;*/
      tables County  * Age_Years * outcome / nocol  ;
      format   County $MesaFmt.   Age_Years AgeFmt.   outcome $Outcome_2cat.   ;
      title1 'Case fatality ratio';
      title2 'data= MMWR_cases';
run;



**   8. Case fatality ratio among those hospitalized   **;

   PROC freq data= MMWR_cases ;
      where hospitalized=1;
      tables  hospitalized;
      tables County  * Age_Years * outcome / nocol  ;
      format   County $MesaFmt.   Age_Years AgeFmt.   outcome $Outcome_2cat.  hospitalized HospFmt. ;
      title1 'Case fatality ratio among hospitalized';
      title2 'data= MMWR_cases ';
run;



***-----------------------***;
***  SECTION 2 OF TABLE   ***;
***  Delta variant cases  ***;
***-----------------------***;


*** 9. Merge demographic variables from CEDRS with B6172 variant data ***;
***___________________________________________________________________***;

/*______________________________________________________________________________________________________*
 | Code below adds demographic variables from above MMWR dataset to the B6172_fix dataset. 
 | B6172_fix dataset is from variant of concern (B.1.617.2) in Colorado. 
 | B6172_read was created from SQL join supplied by Bre. See Read.B6172. 
 | Read.B6172 creates COVID.B6172_read and then Fix.B6172 creates B6172_fix. 
 | Merge demographic vars from CEDRS with B.1.617.2 variant data in B6172_fix. 
 *______________________________________________________________________________________________________*/

PROC sort data= MMWR_cases(keep= ProfileID EventID Hospitalized  Reinfection  Breakthrough Outcome CollectionDate Age_Years)  
   out=MMWRkey; 
   by ProfileID EventID;

PROC sort data= COVID.B6172_fix  out=B6172_key; by ProfileID EventID;
run;

DATA B6172_n_MMWR;
   length County $ 11;
   merge MMWRkey(in=M)  B6172_key(in=V);  
   by ProfileID EventID;

   if V=1 ;                      * <--- which if any is correct? ;
   format County $11.;
   tmp_county=County;
   County=upcase(tmp_county);
   drop tmp_county;
run;

   PROC contents data= B6172_n_MMWR varnum ; run;

   PROC means data= B6172_n_MMWR n nmiss ;
      var CollectionDate ReportedDate  ;
run;

** Delta rate for 0-69 yo by region **;
**_________________________________**;

** Cases in 0-69 yo by region **;
   PROC means data=B6172_n_MMWR  maxdec=2 N nmiss  nway noprint ;
      where 0 < Age_Years < 70;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=N_Y_Deltas(drop=_FREQ_ _TYPE_) n=DeltaCounts;
run;
/*proc print data=N_Y_Deltas ; id County; run;*/

** Calculation of Delta rate per 100K for 0-69 yo by region **;
Data DeltaRate_Y; merge N_Y_Deltas  Y_Pop;  by county;
   DeltasPer100K = (DeltaCounts / (Population/100000) );
   Age_Group='0-69 yo';
run;
/*   PROC print data= DeltaRate_Y;  id county;   format DeltasPer100K 4.0;  run;*/


** Delta rate for 70-109 yo by region **;
**_________________________________**;
   PROC means data=B6172_n_MMWR  maxdec=2 N nmiss  nway noprint ;
      where 69 < Age_Years < 110;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=N_O_Deltas(drop=_FREQ_ _TYPE_) n=DeltaCounts;
run;
/*proc print data=N_O_Deltas ; id County; run;*/

** Calculation of Delta rate per 100K for 70-109 yo by region **;
Data DeltaRate_O; merge  N_O_Deltas  O_Pop;  by county;
   if DeltaCounts=. then DeltaCounts=19;
   DeltasPer100K = (DeltaCounts / (Population/100000) );
   Age_Group='70-109 yo';
   if DeltasPer100K=. then delete;
run;
/*   PROC print data= DeltaRate_O;  id county;  format DeltasPer100K 4.0;  run;*/


** Delta rate in ALL by region **;
**_________________________________**;
   PROC means data=B6172_n_MMWR  maxdec=2 N nmiss  nway noprint ;
      var ReportedDate  ;
      class   County  ;
      format  County   $MesaFmt. ;
      output out=N_Deltas(drop=_FREQ_ _TYPE_) n=DeltaCounts;
run;
/*proc print data=N_Deltas ; id County; run;*/

** Calculation of case rate per 100K for ALL by region **;
Data DeltaRate_All; merge N_Deltas  All_Pop;  by county;
   DeltasPer100K = (DeltaCounts / (Population/100000) );
   Age_Group='ALL';
/*   PROC print data= DeltaRate_All;   id county;  format DeltasPer100K 4.0;   run;*/


** Put Delta rate stats for all three population groups together **;
**______________________________________________________________**;

Data DeltaRate100K_temp; set   DeltaRate_Y   DeltaRate_O  DeltaRate_All   ;
   format DeltaCounts Population comma11.0   DeltasPer100K 5.0;
   proc sort data= DeltaRate100K_temp  out= DeltaRate100K ;  by county;
   PROC print data= DeltaRate100K ;  id County; by County;
      var Age_Group DeltaCounts Population DeltasPer100K;
run;



** 10. Delta Hospitalizations by Age group and Region **;
   PROC freq data= B6172_n_MMWR ;
/*      tables  County  Age_Years hospitalized / missing missprint;*/
      tables County  * Age_Years * hospitalized / nocol  missing missprint ;
      format   County $MesaFmt.   Age_Years AgeFmt.  hospitalized HospFmt.   ;
run;



**   11. Delta Case fatality ratio   **;
   PROC freq data= B6172_n_MMWR ;
/*      tables  County  Age_Years outcome;*/
      tables County  * Age_Years * outcome / nocol  missing missprint ;
      format   County $MesaFmt.   Age_Years AgeFmt.   outcome $Outcome_2cat.   ;
run;



**   12. Delta Case fatality ratio among those hospitalized   **;
   PROC freq data= B6172_n_MMWR ;
      where hospitalized=1;
/*      tables  hospitalized;*/
      tables County  * Age_Years * outcome / nocol missing missprint ;
      format   County $MesaFmt.   Age_Years AgeFmt.   outcome $Outcome_2cat.  hospitalized HospFmt.  ;
run;



***----------------------------------------***;
***  Estimates for text in draft document  ***;
***----------------------------------------***;

**   13. Number of cases as of June 6th for ALL of Colorado and for Mesa (%) **;
   PROC means data= COVID.B6172_fix n nmiss ;
      where ReportedDate  < '07JUN21'd ;* AND  County='Mesa';
      var  ReportedDate Age_years ;
      title1 'from COVID.B6172_fix';
/*      title2 'Delta variant cases from MESA county';*/
      title2 'Delta variant cases from ALL Colorado counties';
run;



*** Datasets for Rachel S. ***;
***------------------------***;
Data DeltaEvents; set B6172_n_MMWR; 
   keep ProfileID EventID LastName FirstName ResultText Age BirthDate ReportedDate ResultDate;
run;


Data COVID_Events; set MMWR_cases; 
   keep ProfileID EventID County CollectionDate ReportedDate Age;
run;



*** export data to google drive ***;
***-----------------------------***;

libname mydata 'C:\Users\eabush\Documents\CDPHE\Requests\data';

DATA mydata.MMWR_ICU ; set MMWR_ICU;  run;

DATA mydata.B6172_n_MMWR ; set B6172_n_MMWR;  run;



DATA COVID.MMWR_cases ; set MMWR_cases;  run;
DATA COVID.B6172_n_MMWR ; set B6172_n_MMWR;  run;
DATA COVID.MMWR_ICU ; set MMWR_ICU;  run;

