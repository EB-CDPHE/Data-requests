/**********************************************************************************************
PROGRAM:  RFI.LR_on_Time_since_Vax.sas
AUTHOR:   Eric Bush
CREATED:  September 29, 2021
MODIFIED:	
PURPOSE:	 RFI for logistic regression on vaccine breakthrough cases
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/


options pageno=1;

**  PROC contents of starting dataset  **;
   PROC contents data= TimeSinceVax  varnum ; title1 'TimeSinceVax'; run;



*** STEP 2 -  Univariate analysis  ***;
***--------------------------------***;

   PROC freq data= TimeSinceVax;
      tables  Age_Group  Gender_Code Vaccination_Code Breakthrough ;
title2 'Univariate analysis of selected predictor variables';  
    ** excluded continuous variables:  Age  AND  Followup_Time  AND  Time_Since_Vax   **;
run;


** STEP 3 -  Logit plots of continuous and ordinal variables  **;
**------------------------------------------------------------**;

DATA TSV; set TimeSinceVax;
   AgeGrp=0;
   If Age_Group = '18-29' then AgeGrp=1;
   If Age_Group = '30-39' then AgeGrp=2;
   If Age_Group = '40-49' then AgeGrp=3;
   If Age_Group = '50-59' then AgeGrp=4;
   If Age_Group = '60-69' then AgeGrp=5;
   If Age_Group = '70-79' then AgeGrp=6;
   If Age_Group = '80+'   then AgeGrp=7;

   Gender=0;
   If Gender_code = 'F' then Gender=1;
   If Gender_code = 'M' then Gender=2;
   If Gender_code = 'U' then Gender=3;

   VxType=0;
   If Vaccination_Code = 'Janssen' then VxType=1;
   If Vaccination_Code = 'Moderna' then VxType=2;
   If Vaccination_Code = 'Pfizer' then VxType=3;

run;
/*   proc freq data=TSV; tables Age_Group * AgeGrp / list; run;*/

title2 'Logit plots of continuous and ordinal variables';  options pageno=1;

** for ordinal variables **;
%macro BinO(dso, outcomeo, varo);
proc means data=&dso nway noprint;
	class &varo;    var &outcomeo &varo;
	output out=Obins  sum(&outcomeo)=&outcomeo ;
data Obins; set Obins;
	logit = log((&outcomeo+1) / (_freq_-&outcomeo+1));
proc gplot data=Obins;
	plot logit*&varo;    symbol v=star i=none;
	title4 "Estimated logit plot of &varo";
run;  quit;
%mend;

%BinO(TSV, Breakthrough, AgeGrp) 


** for continuous variables **;
%macro BinC(ds, outcome, var);
proc rank data=&ds groups=10  out=rank;
	var &var;   ranks bin;
proc means data=rank nway noprint;
	class bin;    var &outcome &var;
	output out=bins  sum(&outcome)=&outcome  mean(&var)=&var;
data bins; set bins;
	logit = log((&outcome+1) / (_freq_-&outcome+1));
proc gplot data=bins;
	plot logit*&var;    symbol v=star i=none;
	title4 "Estimated logit plot of &var";
run;  quit;
%mend;

%BinC(TimeSinceVax, Breakthrough, Age)
%BinC(TimeSinceVax, Breakthrough, Followup_Time)
%BinC(TimeSinceVax, Breakthrough, Time_Since_Vax)


**  Adding quadratic term for Age  **;
   PROC univariate data=TSV plot normal; var AgeGrp;  run;

DATA TSV_age; set TSV;
   Age_neg = -1*Age;
   Age_inv = 1/Age;
   Age_sq = Age*Age;
   Age_cube = Age*Age*Age;
   Age_log = log10(Age);
   Age_ln = log(Age);
run;

  PROC logistic desc data=TSV_age ;
/*    model  Breakthrough =Age_neg     / clodds=pl  ;*/
/*    model  Breakthrough =Age_inv  / clodds=pl  ;*/
/*    model  Breakthrough =Age_sq  / clodds=pl  ;*/
/*    model  Breakthrough =Age_cube  / clodds=pl  ;*/
/*    model  Breakthrough =Age_log  / clodds=pl  ;*/
/*    model  Breakthrough =Age_ln  / clodds=pl  ;*/
    model  Breakthrough =Age Age_sq  / clodds=pl  ;
/*    class AgeGrp / param=ref;*/
/*    model  Breakthrough = AgeGrp  / clodds=pl  ;*/
run;


/*----------------------------------------------------------------------------------------*
 |FINDINGS:
 | Age_Group should be put on the CLASS statment since it is non-linear in logit
 | So it will NOT be treated as an ordinal variable.
 | Follow-up time is linear in logit so can keep as a continuous variable.
 | Time since vaccination is linear in logit so can keep as a continuous variable.
 | Age is NOT linear in the logit; several transformations were tested.
 | Age squared resulted in the lowest AIC.
 *----------------------------------------------------------------------------------------*/



/*ods trace on / listing;*/
ods listing close;
ods output nobs=denom  bestsubsets=score;
  proc logistic desc data=TSV ;
/*    class Gender_Code  Vaccination_Code / param=ref;*/
    model  Breakthrough = Gender  VxType  Followup_Time   Time_Since_Vax  Age Age*Age
     / selection =score best=3  ;
    title4 'Model selection - best subsets';
run;
/*ods trace off;*/
ods listing;
/*proc print data= denom;  proc print data= score;  run;*/
data denom; set denom;
	if label='Number of Observations Used';
	call symput('obs', N);
data subset; set score;
	sc = -scorechisq + log(&obs) * (numberofvariables+1);
	aic = -scorechisq+2 * (numberofvariables+1);

proc sort data=subset;   by sc;
proc print data=subset;  var sc  variablesinmodel ;
proc sort data=subset;   by aic;
proc print data=subset;  var  aic variablesinmodel ;
run;






***  STEP 5  Model building  (TAKE 2)  ***;
***------------------------------------------***;

  proc logistic desc data=TimeSinceVax ;
    class  Gender_Code  Vaccination_Code  / param=ref;
    model  Breakthrough =  Gender_Code  Vaccination_Code  Followup_Time  Time_Since_Vax  Age  Age*Age
                           Gender_Code | Vaccination_Code | Followup_Time | Time_Since_Vax | Age  @3
           / selection =forward slentry=.001 hierarchy=single include=6 ;
    title4 'Model selection - forward (single) ';
run;


/*--------------------------------------------------------------*
 |FINDINGS: Four 2-way interaction terms are significant:
 | 1. Followup_Time  *  Time_Since_Vax
 | 2. Time_Since_Vax  *  Age
 | 3. Time_Since_Vax  *  Vaccination_Code
 | 4. Followup_Time  *  Vaccination_Code
 | AND one 3-way interaction term was significant:
 | 5. Followup_Time  *  Time_Since_Vax  *  Vaccination_Code
 *--------------------------------------------------------------*/

title;  options pageno=1;
  proc logistic desc data=TimeSinceVax ;
    class Gender_Code  Vaccination_Code / param=ref;
    model Breakthrough =  Gender_Code  Vaccination_Code  Followup_Time  Time_Since_Vax  Age Age*Age
     / clodds=pl  ;
    title2 'Full model - main terms only ';
run;

options pageno=1;
  proc logistic desc data=TimeSinceVax ;
    class Gender_Code  Vaccination_Code / param=ref;
    model Breakthrough = Followup_Time  Time_Since_Vax  Age Age*Age
     / clodds=pl  ;
    title2 'Best model - no interaction terms ';
run;

options pageno=1;
  proc logistic desc data=TimeSinceVax ;
    class Gender_Code  Vaccination_Code / param=ref;
    model Breakthrough = Followup_Time  Time_Since_Vax  Age Age*Age  Vaccination_Code
                        Followup_Time*Time_Since_Vax
                        Time_Since_Vax  *  Age
                        Time_Since_Vax  *  Vaccination_Code
                        Followup_Time  *  Vaccination_Code
                        Followup_Time * Time_Since_Vax * Vaccination_Code
         / clodds=pl  ;
    title2 'Best model - main terms and 2 and 3 way interactions ';
run;

***  STEP 6:  Assessment of best models  ***;
***--------------------------------------***;

 title;  options pageno=1;
  proc logistic desc data=TimeSinceVax ;
    class   Vaccination_Code / param=ref;
    model  Breakthrough = Followup_Time  Time_Since_Vax  Age Age*Age  Vaccination_Code
                        Followup_Time*Time_Since_Vax
                        Time_Since_Vax  *  Age
                        Time_Since_Vax  *  Vaccination_Code
                        Followup_Time  *  Vaccination_Code
                        Followup_Time * Time_Since_Vax * Vaccination_Code  /  aggregate scale=none lackfit rsq  ;
    title2 'Final Model - goodness of fit and predictive ability';
run;



***  STEP 7:  Model diagnostics  ***;
***------------------------------***;

title3 'Model diagnostics';  title4;  options pageno=1;
  proc logistic desc data=TimeSinceVax ;
    model  Breakthrough = Followup_Time  Time_Since_Vax  Age Age*Age / influence iplots ;
    title4 'Final Model - diagnostics';
run;

  proc logistic desc data=pmwsrisk noprint;
    model  Breakthrough = Followup_Time  Time_Since_Vax  Age Age*Age / influence iplots ;
    output out=predict p=pred difdev=difdev ;
run;

  proc gplot data=predict;
    plot difdev*pred / vref=4;
    symbol i=none v=star;
    axis1 label=(a=-90 r=90);
    title4 'Difference in deviance by predicted probabilities';
run;
