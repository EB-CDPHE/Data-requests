/**********************************************************************************************
PROGRAM:  RFI.Historical_case_counts.sas
AUTHOR:   Eric Bush
CREATED:  September 21, 2021
MODIFIED:	
PURPOSE:	 CDC request for historical data 
INPUT:	 COVID.County_Population   COVID.CEDRS_view_fix	
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

TITLE;
OPTIONS pageno=1;


*** Create timeline of all dates ***;
***------------------------------***;

DATA timeline;
   ReportedDate='01MAR20'd;
   output;
   do t = 1 to 575;
      ReportedDate+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop t ;
run;
proc print data= timeline;  run;


*** Create local copy of CEDRS case data for selected variables  ***;
***--------------------------------------------------------------***;

   PROC contents data=COVID.CEDRS_view_fix varnum ;  title1 'COVID.CEDRS_view_fix';  run;

DATA CO_cases;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL' ;
   keep ReportedDate  CaseStatus  Outcome ;
run;

   PROC contents data=CO_cases varnum ;  title1 'CO_cases';  run;


*** Colorado - Daily Case counts by status ***:
***----------------------------------------***;

**  Create age specific dataset and sort by date  **;
  PROC sort data=CO_cases  
             out= Rpt_Date_sort; 
      by ReportedDate;
run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Cases_counted; set Rpt_Date_sort;
   by ReportedDate;

   * set accumulator vars to 0 for first ReportedDate in group *;
   if first.ReportedDate then DO;  NumProbable=0;  NumConfirmed=0;  NumProbDead=0;  NumConfDead=0;   END;

   * count daily cases (i.e. sum within ReportedDate group) *;
   if CaseStatus = 'probable' then do;
      NumProbable+1;
      if outcome = 'Patient died' then NumProbDead+1;
   end;

   if CaseStatus = 'confirmed' then do;
      NumConfirmed+1;
      if outcome = 'Patient died' then NumConfDead+1;
   end;

   * keep last ReportedDate in group (with daily totals) *;
   if last.ReportedDate then output;

   * drop patient level variables  *;
   drop  CaseStatus  Outcome   ;
run;


** add ALL reported dates for populations with sparse data **;
Data Colorado_dates;  merge Timeline  Cases_counted;
   by ReportedDate;

   * backfill missing with 0 and add vars to describe population *;
   if NumConfirmed=. then NumConfirmed=0 ; 
   if NumProbable=. then NumProbable=0 ; 

   if NumConfDead=. then NumConfDead=0 ; 
   if NumProbDead=. then NumProbDead=0 ; 

   * create total vars *;
   TotalCases = NumProbable + NumConfirmed ;
   TotalDead = NumProbDead + NumConfDead ;

run;


*** Check numbers ***;
***---------------***;

* Starting dataset (Patient level) *;
   PROC freq data= CO_cases ;  tables CaseStatus  Outcome ;  run;

 * Reduced dataset (Date level) *;
  PROC means data= Colorado_dates  sum maxdec=0;
      var  NumProbable  NumConfirmed  TotalDead ;
run;


***  Calculate Cumulatitive values and totals  ***;
***--------------------------------------------***;

Data Cases_stats; set Colorado_dates;
   by ReportedDate;

* calculate cumulative counts *;
   CumConfirmed + NumConfirmed;
   CumProbable + NumProbable;
   CumConfDead + NumConfDead;
   CumProbDead + NumProbDead;

* create total vars *;
   TotalCumCases = CumProbable + CumConfirmed ;
   TotalCumDead = CumProbDead + CumConfDead ;

   DailyChangeCases = TotalCumCases - lag(TotalCumCases); 
   DailyChangeDead = TotalCumDead - lag(TotalCumDead);

* add labels *;
   LABEL 
      NumConfirmed = 'New confirmed cases for the day'
      NumProbable = 'New probable cases for the day'
      TotalCases = 'Total of Confirmed and Probable cases'

      NumConfDead = 'Confirmed cases that died'
      NumProbDead = 'Probable cases that died day'
      TotalDead = 'Total of Confirmed and Probable deaths'

      CumConfirmed = 'Cumulative total of confirmed cases'
      CumProbable = 'Cumulative total of probable cases'
      TotalCumCases = 'Cumulative total of all cases'

      CumConfDead = 'Confirmed cases that died'
      CumProbDead = 'Probable cases that died day'
      TotalCumDead = 'Cumulative total of all deaths'  ;

run;


***  Evaluate outcome  ***;
***--------------------***;

   PROC print data= Cases_stats l; 
      where ReportedDate ge '01MAR20'd;
      sum  NumConfirmed  NumProbable  TotalCases  NumConfDead  NumProbDead  TotalDead;
run;

   PROC means data= Cases_stats n sum maxdec=0;
      var NumConfirmed  NumProbable  TotalCases  NumConfDead  NumProbDead  TotalDead  ;
run;


***  Export data to CSV  ***;
***----------------------***;

PROC EXPORT DATA= WORK.Cases_stats 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\His
torical case counts by status\Colorado_Historical_data_092321.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;
