/**********************************************************************************************
PROGRAM:  RFI.HospRates7d_Race.sas
AUTHOR:   Eric Bush
CREATED:  March 14, 2022
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



*** Colorado Population counts by Race-Ethnicity ***;
***----------------------------------------------***;

DATA CO_Pop7;  length Race_Ethnicity $ 50 ;  set DASH.County_Population;
**  --> NOTE:  Lumps non-Hispanics and Unknown/Unreported together  <--  **;
        if Race_Ethnicity = 'White' then Race_Ethnicity='White (Non-Hispanic)';
   else if Race_Ethnicity = 'Hispanic, All Races' then Race_Ethnicity='Hispanic (All Races)';
   else if Race_Ethnicity = 'Black or African American' then Race_Ethnicity='Black (Non-Hispanic)';
   else if Race_Ethnicity = 'American Indian or Alaska Native' then Race_Ethnicity='American Indian/Alaskan Native (Non-Hispanic)';
   else if Race_Ethnicity in ('Asian','Native Hawaiian or Other Pacific Islander') then Race_Ethnicity='Asian/Pacific Islander (Non-Hispanic)';

   format Race_Ethnicity $50.;
run;

   PROC means data=CO_Pop7 maxdec=0  sum  noprint; 
      var population; 
      class Race_Ethnicity; 
      output out=RaceCatPop7 sum=Population;
run;
DATA CO_Population7; set RaceCatPop7;
   where _TYPE_=1;
   drop _Type_ _FREQ_ ;
run;

   PROC contents data=CO_Population7 varnum; title1 'CO_Population7'; run;

   PROC print data=CO_Population7 ; sum population; run;



*** Create timeline of all dates ***;
***------------------------------***;

title1;
DATA timeline;
   Hosp_Admission_first='01MAR20'd;
   output;
   do t = 1 to 760;
      Hosp_Admission_first+1;
      output;
   end;
   format Hosp_Admission_first mmddyy10.;
   drop t ;
run;
/*proc print data= timeline;  run;*/



*** Create local copy of filtered data for selected variables  ***;
***------------------------------------------------------------***;

DATA COPHS_filter;  length Race_Ethnicity $ 50 ;  set COVID.COPHS_fix;
   where ('01MAR2020'd  le  Hosp_Admission le  '31JUL2022'd)  AND  CO=1 ;

**  --> NOTE:  Lumps non-Hispanics and Unknown/Unreported together  <--  **;
   if Ethnicity = 'Hispanic or Latino' then Race_Ethnicity='Hispanic (All Races)';
   else if Race = 'American Indian/Alaskan Native' then Race_Ethnicity='American Indian/Alaskan Native (Non-Hispanic)';
   else if Race in ('Asian','Pacific Islander/Native Hawaiian') then Race_Ethnicity='Asian/Pacific Islander (Non-Hispanic)';
   else if Race = 'Black, African American' then Race_Ethnicity='Black (Non-Hispanic)';
   else if Race = 'White' then Race_Ethnicity='White (Non-Hispanic)';
   else Race_Ethnicity=Race;


   Keep MR_Number  Race  Ethnicity  County_of_Residence  CO  Hosp_Admission     
        Race_Ethnicity ;
run;

   PROC contents data=COPHS_filter  varnum; title1 'COPHS_filter'; run;

   PROC freq data=COPHS_filter ; tables Race_Ethnicity; run;
