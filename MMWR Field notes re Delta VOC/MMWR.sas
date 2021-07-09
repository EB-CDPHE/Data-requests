/**********************************************************************************************
PROGRAM: MMWR.sas
AUTHOR:  Eric Bush
CREATED: July 8, 2021
MODIFIED:	
PURPOSE:	Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		COVID.CEDRS_view   COVID.B6172_fix   COVID.County_Population
OUTPUT:		      MMWR_cases
***********************************************************************************************/

** Filter CEDRS data for analysis to records with collection date between Apr 20 - Jun 19 **;
** Basically same as MMWR_cases dataset but with start date pushed back to March 15 (Wk11) **;

DATA SpringWave;  set FixCollDate ;
   where '15MAR21'd le CollectionDate le '19JUN21'd;
   if CountyAssigned = 'INTERNATIONAL' then delete;
   if Age_Years > 109 then Age_Years = .;
run;

 PROC contents data= SpringWave  ;
      title1 'COVID.CEDRS_view obs between April 20 - June 19';
run;


   proc means n nmiss data=SpringWave ;
      var ReportedDate CollectionDate OnsetDate_proxy_dist ;
run;

   PROC freq data= SpringWave;
/*      tables ReportedDate CollectionDate OnsetDate_proxy_dist / nopercent;*/
/*      format ReportedDate CollectionDate OnsetDate_proxy_dist weekW5.;*/
run;

   PROC freq data= SpringWave order=freq;
      tables county;
run;


** Cases in ALL by region **;
   PROC means data=SpringWave  maxdec=2 N nmiss  nway noprint ;
      var ReportedDate  ;
      class   County  ;
      output out=County_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
run;
/*   proc print data= County_Cases; run;*/
** Population of ALL by region **;
   PROC means data= County_Population  sum nway noprint; 
      class County ;
      var Population ;
      output out=County_Pop(drop=_TYPE_ _FREQ_) sum=Population;
run;
/*   proc print data= County_Pop; run;*/

   proc sort data= County_Cases; by County;
   proc sort data= County_Pop; by County;
DATA County_CaseRate; merge County_Cases County_Pop;  by County;
   CasesPer100K = (CaseCounts/ (Population/100000) );
run;

   proc sort data= County_CaseRate; by descending CasesPer100K;
   proc print data= County_CaseRate; 
      ID County;
run;

proc univariate data= County_CaseRate; var CasesPer100K; run;

proc format; 
   value RateCat
      low-1000='low'
      1000-2000='med'
      2000-high='high' ;
   value CntyPopFmt
      '', '', '', '', '', '', '', '', '' = 'High Pop'
run;

   proc sort data= County_CaseRate; by descending CaseCounts;
   proc print data= County_CaseRate; 
      ID County;
      format CasesPer100K RateCat. ;
run;


proc freq data= County_CaseRate order=freq;
   tables county;
   weight population;
   run;




** Calculation of case rate per 100K for ALL by region **;
Data CaseRate_All; merge N_Cases  All_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='ALL';
run;


proc print data=N_O_Deltas   ; run;
proc print data= O_Pop  ; run;


proc contents data=N_Y_Deltas  varnum ; run;
proc contents data= Y_Pop varnum ; run;



** RUN the Key_merge.COPHS.CEDRS.sas program to link COPHS ICU admission to MMWRcases dataset. **;


***  Merge ICU key with MMWRcases data   ***;
***______________________________________***;

DATA B6172_key;  
   length  ProfileID $ 15;   
   set  B6172_n_MMWR;

   format  ProfileID $15.;
   keep ProfileID County Age_Years hospitalized ; 
run;
/*   PROC contents data=MMWR_key  varnum ; run;*/
 

   proc sort data=ICU_Key  out=I_key; by ProfileID;
   proc sort data=B6172_key out=B_key; by ProfileID;
DATA B6172_ICU; merge I_key(in=i)  B_key(in=b) ;
   by ProfileID; 
   if i=1 AND b=1;
   if ICU_Admission ne . then ICU=1; else ICU=0;
run;
   PROC print data=B6172_ICU ; id ProfileID; run;

** Contents for final dataset for estimation **;
   PROC contents data=B6172_ICU  varnum ; run;




   proc freq data=B6172_ICU ; tables ICU ICU_Admission; run;
   PROC means data= B6172_ICU  n nmiss ;  var ICU_Admission hospitalized ICU; run;

   PROC freq data= B6172_ICU ;
/*      tables  County  Age_Years hospitalized ICU;*/
      tables County  * Age_Years * ICU / nocol  ;
      format   County $MesaFmt.   Age_Years AgeFmt. ;* hospitalized HospFmt. ;
      title1 'Admission to ICU among hospitalized cases';
      title2 'data= MMWR_ICU';
run;
