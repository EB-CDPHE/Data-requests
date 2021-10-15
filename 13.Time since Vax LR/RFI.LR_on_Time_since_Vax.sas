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


*** STEP 2:  Univariate analysis  ***;
***--------------------------------***;

   PROC freq data= TimeSinceVax;
      tables  Age_Group  Gender_Code Vaccination_Code Breakthrough ;
title2 'Univariate analysis of selected predictor variables';  
    ** excluded continuous variables:  Age  AND  Followup_Time  AND  Time_Since_Vax   **;
run;


*** STEP 3:  Logit plots of continuous and ordinal variables  ***;
***------------------------------------------------------------***;

** change char var to numeric var for proc means **;
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


**  Assessing transformation options for Age var  **;

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


/*---------------------------------------------------------------------------------------*
 |FINDINGS:
 | Age_Group should be put on the CLASS statment since it is non-linear in logit
 | So it will NOT be treated as an ordinal variable.
 | Follow-up time is linear in logit so can keep as a continuous variable.
 | Time since vaccination is linear in logit so can keep as a continuous variable.
 | Age is NOT linear in the logit; several transformations were tested.
 | Age squared resulted in the lowest AIC.
 *---------------------------------------------------------------------------------------*/



***  STEP 4:  Use forward selection to find significant interaction terms  ***;
***------------------------------------------------------------------------***;

  proc logistic desc data=TimeSinceVax ;
    class  Gender_Code  Vaccination_Code  / param=ref;
    model  Breakthrough =  Gender_Code  Vaccination_Code  Followup_Time  Time_Since_Vax  Age  Age*Age
                           Gender_Code | Vaccination_Code | Followup_Time | Time_Since_Vax | Age  @3
           / selection =forward slentry=.0001 hierarchy=single include=6 ;
    title2 'Model selection - Forward selection on Full model with 2 and 3 way interactions';
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



***  STEP 5:  Model building using Best Subsets selection  ***;
***-------------------------------------------------------***;

** Code for Best subsets on Full model with main terms only  **;
  proc logistic desc data=TSV ;
    model  Breakthrough = Gender  VxType  Followup_Time   Time_Since_Vax  Age Age*Age
     / selection=score best=3  ;
    title2 'Model selection - best subsets on full model with main terms only';
run;


** Code for Best subsets on Full model with ALL significant interactions  **;
  proc logistic desc data=TSV ;
    model  Breakthrough = Gender  VxType  Followup_Time   Time_Since_Vax  Age Age*Age
                        Followup_Time*Time_Since_Vax
                        Time_Since_Vax  *  Age
                        Time_Since_Vax  *  VxType
                        Followup_Time  *  VxType
                        Followup_Time * Time_Since_Vax * VxType
     /selection =score best=3  include=6  ;
    title2 'Model selection - best subsets on full model with significant interactions';
run;


** Insert above "Best Subsets" code into ODS code below for SC and AIC by subset **;
ods trace on / listing;
ods output nobs=denom  bestsubsets=score;

options pageno=1;
  proc logistic desc data=TSV ;
    model  Breakthrough = Gender  VxType  Followup_Time   Time_Since_Vax  Age Age*Age
     / selection=score best=3  ;
    title2 'Model selection - best subsets on full model with main terms only';
run;

ods trace off;

data denom; set denom;
	if label='Number of Observations Used';
	call symput('obs', N);
data subset; set score;
	sc = -scorechisq + log(&obs) * (numberofvariables+1);
	aic = -scorechisq+2 * (numberofvariables+1);
run;

   proc sort data=subset;   by numberofvariables sc;
   PROC print data=subset;  var numberofvariables sc  variablesinmodel ;
run;

   proc sort data=subset;   by aic;
   PROC print data=subset;  var  aic variablesinmodel ;
run;


/*----------------------------------------------------------------------------*
 |FINDINGS:
 | Best subsets on full model shows 3 models for each model size (# of vars)
 | SC scores drop sharpy starting with a 2 var model. 
 | AIC for best subset models had 11 models with extremely low scores.
 | Best model per SC and AIC is VB = Follow-up + Time_Since_Vax
 *----------------------------------------------------------------------------*/



***  STEP 6:  Comparison of competing models  ***;
***-------------------------------------------***;

title;  options pageno=1;

**  Model 1: Full model - main effects only  **;
   PROC Logistic desc data=TimeSinceVax ;
      class Gender_Code  Vaccination_Code  / param=ref;
      model Breakthrough = Gender_Code  Vaccination_Code  Followup_Time   Time_Since_Vax  Age Age*Age
     / clodds=pl  ;
    title2 'Full model - main effects only';
run;

**  Model 2: Full model - with ALL significant interactions  **;
   PROC Logistic desc data=TimeSinceVax ;
      class Gender_Code  Vaccination_Code  / param=ref;
      model Breakthrough = Gender_Code  Vaccination_Code  Followup_Time  Time_Since_Vax  Age Age*Age 
                           Followup_Time * Time_Since_Vax
                           Time_Since_Vax * Age
                           Time_Since_Vax * Vaccination_Code
                           Followup_Time * Vaccination_Code
                           Followup_Time * Time_Since_Vax * Vaccination_Code
      / clodds=pl  ;
    title2 'Full model - with ALL significant interactions';
run;


**  Model 3: Competing model (best w age) - main effects only  **;
   PROC Logistic desc data=TimeSinceVax ;
      model Breakthrough =  Followup_Time  Time_Since_Vax   Age Age*Age
      / clodds=pl  ;
   title2 'Competing model (best w age) - main effects only';
run;

**  Model 4: Competing model (best w age) - 2 interaction terms  **;
   PROC Logistic desc data=TimeSinceVax ;
      model Breakthrough =  Followup_Time  Time_Since_Vax  Age Age*Age
                           Followup_Time*Time_Since_Vax
                           Time_Since_Vax  *  Age
      / clodds=pl  ;
   title2 'Competing model (best w age) - 2 interaction terms';
run;


**  Model 5: Best subsets ideal model - main effects only  **;
   PROC Logistic desc data=TimeSinceVax ;
      model Breakthrough = Followup_Time  Time_Since_Vax  
      / clodds=pl  ;
      oddsratio Followup_Time  ;
      oddsratio Time_Since_Vax;
   title2 'Best subsets ideal model - main effects only';
run;

**  Model 6: Best subsets ideal model - with related interaction term  **;
   PROC Logistic desc data=TimeSinceVax ;
      model Breakthrough = Followup_Time  Time_Since_Vax  
                           Followup_Time*Time_Since_Vax
      / clodds=pl  ;
      oddsratio Followup_Time  ;
      oddsratio Time_Since_Vax;
title2 'Best subsets ideal model - w interaction term';
run;



***  STEP 7:  Assessment of final model  ***;
***--------------------------------------***;

 title;  options pageno=1;
   PROC Logistic desc data=TimeSinceVax ;
      model Breakthrough = Followup_Time  Time_Since_Vax  
                           Followup_Time*Time_Since_Vax  /  aggregate scale=none lackfit rsq  ;
    title2 'Final Model - goodness of fit and predictive ability';
run;

/*-----------------------------------------------------------------------------------*
 |FINDINGS:
 | The number of distanct obs is 12,972.
 | The p-value for Deviance and Pearson chi-sq differ so there may be a data issue.
 | (want these values to be large - Deviance is but Pearson is small)
 | Re: predictive power of the model:
 |    a) Generalized R2 = 
 |    b) Max-rescaled R2 = 0.9808 (out of 1)
 | Re: goodness of fit, the Hosmer-Lemeshow Goodness-of-Fit test is significant.
 |    This means there is evidence of lack of fit. 
 |    BUT could this be from large sample size??
 |    OR is this because three of the expected cells are <5??
 *-----------------------------------------------------------------------------------*/



***  STEP 8:  Model diagnostics  ***;
***------------------------------***;

title;  options pageno=1;
  proc logistic desc data=TimeSinceVax ;
    model  Breakthrough = Followup_Time  Time_Since_Vax  Followup_Time*Time_Since_Vax / influence iplots ;
    title2 'Final Model - diagnostics';
run;



/*  proc gplot data=predict;*/
/*    plot difdev*pred / vref=4;*/
/*    symbol i=none v=star;*/
/*    axis1 label=(a=-90 r=90);*/
/*    title4 'Difference in deviance by predicted probabilities';*/
/*run;*/
