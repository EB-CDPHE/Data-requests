/**********************************************************************************************
PROGRAM:  RFI.CDC_Case_counts_COLORADO.sas
AUTHOR:   Eric Bush
CREATED:  March 21, 2022
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


 * Programs run prior to this one *;
/*--------------------------------*
 | 1. Access.CEDRS.sas
 | 2. Fix.CEDRS.sas
 *--------------------------------*/

/*
 | What this program does:
   a) Create timeline dataset of all dates in pandemic
   b) Create local copy of CEDRS case data for selected variables
   c) Reduce dataset from patient level to date level (one obs per date reported)
   d) Add ALL reported dates (from timeline ds) for populations with sparse data
   e) Calculate Daily Case counts by status
   f) Calculate Cumulatitive values and totals
   g) Need to re-order variables to match column headers in Template
   h) Export final dataset to Excel workbook
 */


*** Create timeline of all dates ***;
***------------------------------***;

DATA timeline;
   ReportedDate='01MAR20'd;
   output;
   do t = 1 to 773;                                      * <--  UPDATE NUMBER OF LOOPS HERE;
      ReportedDate+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop t ;
run;
proc print data= timeline;  run;


/*proc freq data= COVID.CEDRS_view_fix; tables CountyAssigned; run;*/


*** Create local copy of CEDRS case data for selected variables  ***;
***--------------------------------------------------------------***;

   PROC contents data=COVID.CEDRS_view_fix varnum ;  title1 'COVID.CEDRS_view_fix';  run;

DATA CO_cases;  set COVID.CEDRS_view_fix;
   keep ReportedDate CaseStatus  Outcome ;
run;

   PROC contents data=CO_cases varnum ;  title1 'CO_cases';  run;


*** Colorado - Daily Case counts by status ***:
***----------------------------------------***;

**  Sort by date  **;
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

   * clean up obs with missing data *;
   if ReportedDate GE '13APR22'd then DELETE;                                * <-- CHANGE DATE HERE ;

run;


*** Check numbers ***;
***---------------***;

options nodate pageno=1;
* Starting dataset (Patient level) *;
   PROC freq data= CO_cases ;  tables CaseStatus  Outcome /missing missprint;  
   title1;  title2 'Starting dataset:  CEDRS_fix';
run;

 * Reduced dataset (Date level) *;
  PROC means data= Colorado_dates  sum maxdec=0;
      var  NumProbable  NumConfirmed  TotalDead ;
   title1; title2 'Summary dataset:  Colorado_dates';
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
      ReportedDate = 'Submission_Date'

      NumConfirmed = 'New_Confirmed_Cases'
      CumConfirmed = 'Total_Confirmed_Cases'

      NumProbable = 'New_Probable_Cases'
      CumProbable = 'Total_Probable_Cases'

      TotalCases = 'Total_New_Cases'
      TotalCumCases = 'Total_Cases'


      NumConfDead = 'New_Confirmed_Deaths'
      CumConfDead = 'Total_Confirmed_Deaths'

      NumProbDead = 'New_Probable_Deaths'
      CumProbDead = 'Total_Probable_Deaths'

      TotalDead = 'New_deaths'
      TotalCumDead = 'Total_Deaths'  ;

run;

***  FINAL dataset  ***;
***-----------------***;

** Need to re-order variables to match column headers in Template **;
DATA Bulk_Daily_13APR2022_Colorado;                                                                * <-- CHANGE DATE HERE ;
   retain ReportedDate
      NumConfirmed  CumConfirmed    NumProbable  CumProbable    TotalCases  TotalCumCases
      NumConfDead   CumConfDead     NumProbDead  CumProbDead    TotalDead   TotalCumDead  ;     
   set Cases_stats;

   DROP  Daily:  ;
run;

   PROC contents data= Bulk_Daily_13APR2022_Colorado varnum;  run;                                * <-- CHANGE DATE HERE ;


***  Evaluate outcome  ***;
***--------------------***;

title;
   PROC print data= Bulk_Daily_13APR2022_Colorado l;                                               * <-- CHANGE DATE HERE ;
      where ReportedDate ge '01MAR20'd;                                                            
      sum  NumConfirmed  NumProbable  TotalCases  NumConfDead  NumProbDead  TotalDead  ;
run;

   PROC means data= Bulk_Daily_13APR2022_Colorado n sum maxdec=0;                                  * <-- CHANGE DATE HERE ;
      var NumConfirmed  NumProbable  TotalCases   ;
   title1; title2 'Final counts: CASES';
run;
   PROC means data= Bulk_Daily_13APR2022_Colorado n sum maxdec=0;                                  * <-- CHANGE DATE HERE ;
      var NumConfDead  NumProbDead  TotalDead   ;
   title1; title2 'Final counts: DEATHS';
run;





***  Export final dataset to Excel workbook  ***;
***------------------------------------------***;

                                                                                           * vvv  CHANGE DATE HERE  vvv ;
PROC EXPORT DATA= WORK.Bulk_Daily_13APR2022_Colorado 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\28.CDC case counts\Output\Bulk_Historical_Update_Colorado_2022-04-13.xlsx" 
            DBMS=EXCEL LABEL REPLACE;
     SHEET="Jurisdictional Aggregate Data"; 
RUN;
