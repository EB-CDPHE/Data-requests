/**********************************************************************************************
PROGRAM:  RFI.Hosp_rates_Race.sas
AUTHOR:   Eric Bush
CREATED:  February 21, 2022
MODIFIED:	
PURPOSE:	 Prep curated and edited COPHS data for use in Tableau 
          to calculate moving average of Hosp rates by Race - Ethnicity
INPUT:	 COVID.COPHS_fix     	  
OUTPUT:	 DASH.COPHS_fix	
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;


 * Programs run prior to this one *;
/*--------------------------------*
 | 1. Access.COPHS.sas
 | 2. Check.COPHS.sas
 | 3. Fix.COHPS.sas
 | 4. GET.CO_Population_Race.sas
 *--------------------------------*/


*** How many COPHS records are for patients outside of CO? ***;
***--------------------------------------------------------***;

   PROC freq data= COVID.COPHS_fix; tables CO; run;

/*-------------------------------------------------------------------*
 |FINDINGS:
 | n=2970 records where CO=0
 | n=86 records where CO=9 (mistakenly classified in COPHS as CO=1
 | Over 95% of records CO=1 (n=61,786);
 | FIX:  Filter on CO=1
 *-------------------------------------------------------------------*/

   PROC freq data= COVID.COPHS_fix; tables Ethnicity * Race / list ; run;
   PROC freq data= COVID.COPHS_fix; tables  Race  ; run;


*** Create local copy of filtered data for selected variables  ***;
***------------------------------------------------------------***;

DATA COPHS_fix;  length Race_Ethnicity $ 40 ;  set COVID.COPHS_fix;
   where ('01MAR2020'd  le  Hosp_Admission le  '31JUL2022'd)  AND  CO=1 ;

**  --> NOTE:  Lumps non-Hispanics and Unknown/Unreported together  <--  **;
   if Ethnicity = 'Hispanic or Latino' then Race_Ethnicity='Hispanic (All Races)';
   else if Race = 'American Indian/Alaskan Native' then Race_Ethnicity='American Indian/Alaskan Native';
   else if Race in ('Asian','Pacific Islander/Native Hawaiian') then Race_Ethnicity='Asian/Pacific Islander (Non-Hispanic)';
   else if Race = 'Black, African American' then Race_Ethnicity='Black (Non-Hispanic)';
   else if Race = 'White' then Race_Ethnicity='White (Non-Hispanic)';
   else Race_Ethnicity=Race;


   Keep Facility_Name MR_Number First_Name Last_Name Gender Race Ethnicity County_of_Residence  CO
        Date_Added COPHS_Breakthrough COVID19ICD10 Hosp_Admission ICU_Admission DOB Positive_Test 
        Race_Ethnicity ;
run;

   PROC contents data=COPHS_fix  varnum; title1 'COPHS_fix'; run;


*** County data ***;
***-------------***;

   PROC freq data= COPHS_fix; 
      tables CO  County_of_Residence ; 
run;


*** Number of cases by Ethnicity and Race ***;
***---------------------------------------***;
   PROC freq data= COPHS_fix; tables  Race_Ethnicity ; run;

   PROC means data=COPHS_fix  n  maxdec=0;
      var Hosp_Admission ;
      class Ethnicity;
      title1 'Number of Hospitalizations:  Hispanics';
run;
   PROC means data=COPHS_fix  n  maxdec=0;
      where Ethnicity ^= 'Hispanic or Latino';
      var Hosp_Admission ;
      title1 'Number of Hospitalizations:  Non-Hispanics';
      class Race;
run;
   PROC means data=COPHS_fix  n  maxdec=0;
      var Hosp_Admission ;
      title1 'Number of Hospitalizations:  Race_Ethnicity';
      class Race_Ethnicity;
      format Race_Ethnicity $22. ;
run;

   PROC freq data= COPHS_fix ;
      tables Hosp_Admission * Race_Ethnicity /norow nocol nopercent  ;
      format Hosp_Admission monyy. ;
      title1 'Number of Hospitalizations:  Race_Ethnicity';
      title2 'by Month';
run;


*** Copy COPHS data to dashboard directory ***;
***----------------------------------------***;

DATA DASH.COPHS_fix; set COPHS_fix;
run;



*** CHECK ***;
*** Use output in spreadsheet to check calculation of moving average of hosp rates ***;
   proc freq data=DASH.COPHS_fix ;
   where ('01DEC2021'd  le  Hosp_Admission le  '31DEC2021'd)  AND Race_Ethnicity = 'American Indian/Alaskan Native' ;
   table Hosp_Admission * Race_Ethnicity   /out=REcases ;
run;
quit; run;

   proc print data= DASH.COPHS_fix ;
   where Race_Ethnicity = 'American Indian/Alaskan Native' ;
run;

