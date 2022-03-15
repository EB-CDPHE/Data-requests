/**********************************************************************************************
PROGRAM:  RFI.HospRates30d_Race.sas
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


 * Programs run prior to this one *;
/*--------------------------------*
 |POPULATION DATA:
 | 1. Access.Populations_Race_Ethnicity.sas
 |COPHS DATA:
 | 1. Access.COPHS.sas
 | 2. Check.COPHS.sas
 | 3. Fix.COHPS.sas
 *--------------------------------*/


*** Colorado Population counts by Race-Ethnicity ***;
***----------------------------------------------***;

DATA CO_Pop;  length Race_Ethnicity $ 50 ;  set COVID.CO_Population_Race_Ethnicity;
**  --> NOTE:  Lumps non-Hispanics and Unknown/Unreported together  <--  **;
        if Race_Ethnicity = 'White' then Race_Ethnicity='White (Non-Hispanic)';
   else if Race_Ethnicity = 'Hispanic, All Races' then Race_Ethnicity='Hispanic (All Races)';
   else if Race_Ethnicity = 'Black or African American' then Race_Ethnicity='Black (Non-Hispanic)';
   else if Race_Ethnicity = 'American Indian or Alaska Native' then Race_Ethnicity='American Indian/Alaskan Native (Non-Hispanic)';
   else if Race_Ethnicity in ('Asian','Native Hawaiian or Other Pacific Islander') then Race_Ethnicity='Asian/Pacific Islander (Non-Hispanic)';

   format Race_Ethnicity $50.;
run;

   PROC means data=CO_Pop maxdec=0  sum  noprint; 
      var population; 
      class Race_Ethnicity; 
      output out=RaceCatPop sum=Population;
run;
DATA CO_Population; set RaceCatPop;
   where _TYPE_=1;
   drop _Type_ _FREQ_ ;
run;

   PROC contents data=CO_Population varnum; title1 'CO_Population'; run;

   PROC print data=CO_Population ; sum population; run;






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



*** TEMPLATE for calculation of Hosp Rate by Race_Ethnicity ***;
***_________________________________________________________***;

** Put population count for Race group into macro var **;
data _null_; set CO_Population ; 
   where Race_Ethnicity = 'White (Non-Hispanic)' ;
   call symputx("ColoPop", population);    * <-- put population value into macro variable;
run;

** Reduce Patient-level dataset to date-level dataset **;
DATA COPHS_Race; set COPHS_filter;
   where Race_Ethnicity = 'White (Non-Hispanic)';
run;

** sort by MR_Number and create patient-level dataset   **;
  PROC sort data=COPHS_Race  
             out= COPHS_Race_sort; 
      by MR_Number Hosp_Admission ;
run;

**  Reduce dataset from admission level to patient level  **;
Data COPHS_Race_patient; set COPHS_Race_sort;
   by MR_Number;

   * count cases per reported date *;
   if first.MR_Number then DO;  NumHosp_perPat=0; Hosp_Admission_first = Hosp_Admission;  END;
   retain Hosp_Admission_first;
   NumHosp_perPat+1;

   IF last.MR_Number then DO;
      Hosp_Admission_last = Hosp_Admission;

      output;
   END;

   format Hosp_Admission_first  Hosp_Admission_last  mmddyy10.; 

* drop admission level variables  *;
   drop  Hosp_Admission   ;
run;

** sort by Hosp_Admission_first   **;
  PROC sort data=COPHS_Race_patient  
             out= COPHS_Race_date; 
      by Hosp_Admission_first ;
run;


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data COPHS_Race_rate; set COPHS_Race_date;
   by Hosp_Admission_first;

* count cases per reported date *;
   if first.Hosp_Admission_first then NumHosp_perDay=0;
   NumHosp_perDay+1;

* calculate daily case rate  *;
   if last.Hosp_Admission_first then do;
      HospRate= NumHosp_perDay / (&ColoPop / 100000);
      output;
   end;

* drop patient level variable *;
   DROP  MR_Number  CO  County_of_Residence ;
run;
   proc print data= COPHS_Race_rate ;  ID Hosp_Admission_first ;  run;

    
** add ALL reported dates for populations with sparse data **;
** Merge Timeline with case rate data **;
Data COPHS_Race_dates;  merge Timeline  COPHS_Race_rate;
   by Hosp_Admission_first;

* backfill missing with 0 *; 
   if NumHosp_perDay=. then NumHosp_perDay=0 ; 

   if HospRate = . then HospRate = 0 ; 

*add vars to describe population (which will be missing for obs from Timeline only) *;
   Race_Ethnicity = 'White (Non-Hispanic)';
run;


**  Calculate 7-day moving averages  **;
   PROC expand data=COPHS_Race_dates   out=MovingAverage_White  method=none;
      id Hosp_Admission_first;
      convert NumHosp_perDay=NumHosp30dAv / transformout=(movave 30);
      convert HospRate=Hosp30dAv / transformout=(movave 30);
run;

   PROC contents data=MovingAverage_White varnum ;  title1 'MovingAverage_White';  run;


* delete temp datasets not needed *;
proc datasets library=work NOlist ;
   delete  COPHS_Race   COPHS_Race_sort   COPHS_Race_patient   COPHS_Race_date   COPHS_Race_rate   COPHS_Race_dates  ;
quit;
run;


*** RUN MACRO for each Race-Ethnicity group ***;
***-----------------------------------------***;

%include 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.RaceRates.sas';


%RaceRates(Hispanic (All Races), MovingAverage_Hispanic)
%RaceRates(White (Non-Hispanic), MovingAverage_White)
%RaceRates(Black (Non-Hispanic), MovingAverage_Black)
%RaceRates(American Indian/Alaskan Native (Non-Hispanic), MovingAverage_NatAmer)
%RaceRates(Asian/Pacific Islander (Non-Hispanic), MovingAverage_Asian)
%RaceRates(Other, MovingAverage_Other)


***  Combine the Race datasets into one dataset  ***;
***----------------------------------------------***;

Data MovingAverage_Race ; 
   set   MovingAverage_White    
         MovingAverage_Black    
         MovingAverage_Hispanic   
         MovingAverage_NatAmer  
         MovingAverage_Asian  
         MovingAverage_Other ;
run;


*** Merge combined moving averages by Race with Population count by Race ***;
   proc sort data= MovingAverage_Race
               out= MovingAverage_Sort;
      by Race_Ethnicity;
   proc sort data= CO_Population
               out= CO_Population_Sort;
      by Race_Ethnicity;
run;

DATA HospRates30d_by_Race; merge  MovingAverage_Sort  CO_Population_Sort ;
   by Race_Ethnicity;
run;


**  Save combined dataset to Dashboard data directory (for Tableau)  **;

libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;

DATA DASH.HospRates30d_by_Race; set  HospRates30d_by_Race;
run;

   PROC contents data= DASH.HospRates30d_by_Race varnum; title1 'DASH.HospRates30d_by_Race'; run;
