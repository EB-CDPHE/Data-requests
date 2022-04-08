/**********************************************************************************************
PROGRAM:  RFI.CDC_Case_counts_COUNTY.sas
AUTHOR:   Eric Bush
CREATED:  March 21, 2022
MODIFIED: 040822:  Add in code for calculating cumulatitve values and totals	
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

/*__________________________* 
 | What this program does:  |
 *_________________________________________________________________________________________________*
 | First data source:  LIBNAME = A2Pop; DATA = CountyRankings.XLSX
 | a) Pull out a section of code from the GET.Demographics.sas program, specifically section A2.
 |    Use this to obtain county level identifiers which links County name with County FIPS code.
 | b) Add in county level variables that are part of the Excel template, i.e. State Abbr 
 |    and State FIPS code. Also strip 'county' from County name variable. 
 | c) Create observation for "Unallocated" county and add to County dataset.
 |
 | Second data source: LIBNAME = COVID;  DATA = CEDRS
 | a) Create a local copy of CEDRS dataset. Keep only four variables.
 |    Change County="INTERNATIONAL' to 'Unallocated';
 | b) sort by County and Date
 | c) reduce from Patient-level to Date-level dataset
 | d) count daily cases (i.e. sum within ReportedDate group) by Status.
 |    Drop patient level variables (CaseStatus and Outcome)
 |
 | Merged data sources:
 | e) Merge with Timeline and do the following:
 |    - backfill missing values with zeros
 |    - create Total variables that tally counts across status
 |    - truncate dataset to current date
 | f) Check numbers by comparing totals from patient-level CEDRS dataset to processed dataset
 | g) 
 *_________________________________________________________________________________________________*/



*** Get link between County FIPS and County name ***;
***----------------------------------------------***:

** Create libname with XLSX engine that points to XLSX file **;
libname A2Pop xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data\demographics\CountyRankings.xlsx' ; run;

   proc contents data= A2Pop.data  varnum ; run;

** Create SAS dataset from SDO spreadsheet **;
DATA CO2020est_Cnty;   
   set A2Pop.data;

   where County_FIPS ^= '000' ;          * For STATE-level use ='000' ;
                                         * For COUNTY-level use ^='000' ;
   length CountyAssigned $ 22;
   CountyAssigned = trim(tranwrd(Area, 'COUNTY','') ) ;

   length county $ 20;
   county = PropCase(Area) ;

   length countyFIPS $ 5;
   countyFIPS = cats('08', County_FIPS);

   StateAbbr='CO';
   StateFIPS='08';  

   KEEP countyFIPS  County_FIPS  StateAbbr  StateFIPS   CountyAssigned  County  ; 
run;

** Create observation for "Unallocated" county **;
DATA Unallocated;  
   length CountyAssigned $ 22;
   CountyAssigned = 'Unallocated Colorado' ;
   format CountyAssigned $22.;
   county = 'Unallocated Colorado';
   StateAbbr='CO';
   StateFIPS='08';
   County_FIPS = '000' ;
   countyFIPS='08000';
run;

** Add Unallocated county data to County dataset **;
DATA CO_Counties;  set Unallocated  CO2020est_Cnty ;
run;

** Contents of dataset **;
   PROC contents data=CO_Counties  varnum ; title1 'CO_Counties'; run;

** View of dataset **;
   PROC print data=CO_Counties; 
      id countyFIPS; var  county  StateAbbr  StateFIPS  County_FIPS  CountyAssigned ;
run;


** Create complete timeline for each County **;
/*------------------------------------------**
 | NOTE: This makes it so each County has a   
 | row for every day of the pandemic. 
 | UPDATE number of loops as needed.
*--------------------------------------------*/
DATA County_Timeline; set CO_Counties; 
   by CountyFIPS;

   if first.CountyFIPS then DO;
   ReportedDate='01MAR20'd;
   output;
   do t = 1 to 770;                                   * <--  UPDATE NUMBER OF LOOPS HERE;
      ReportedDate+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop t ;
   END;
run;

   PROC sort data=County_Timeline
               out=County_Timeline_sort ;
      by CountyAssigned ReportedDate;
run;

 ** View of dataset **;
   proc print data= County_Timeline_sort;  run;

 ** Contents of dataset **;
/*  PROC contents data=County_Timeline_sort  varnum ; title1 'County_Timeline_sort'; run;*/



*** Create local copy of CEDRS case data for selected variables  ***;
***--------------------------------------------------------------***;

   PROC contents data=COVID.CEDRS_view_fix varnum ;  title1 'COVID.CEDRS_view_fix';  run;

DATA CO_county_cases;  
   length CountyAssigned $ 22;
   set COVID.CEDRS_view_fix;

   if CountyAssigned = 'INTERNATIONAL' then  CountyAssigned = 'Unallocated Colorado' ;
   format CountyAssigned $22.;
   keep ReportedDate CountyAssigned CaseStatus  Outcome  ;
run;

   PROC contents data=CO_county_cases varnum ;  title1 'CO_county_cases';  run;


*** Colorado - Daily Case counts by status ***:
***----------------------------------------***;

**  Sort by County and Date  **;
  PROC sort data=CO_county_cases  
             out= CO_county_cases_sort; 
      by CountyAssigned ReportedDate;
run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data County_Cases_counted; set CO_county_cases_sort;
   by CountyAssigned ReportedDate;

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



*** Add in Timeline for each County ***;
***---------------------------------***;

 ** Sort dataset **;
   PROC sort data=County_Timeline
               out=County_Timeline_sort ;
   by CountyAssigned ReportedDate;
run;

** add ALL reported dates for populations with sparse data **;
Data Colorado_County_dates;  merge County_Timeline_sort  County_Cases_counted;
   by CountyAssigned ReportedDate;

   * backfill missing with 0 and add vars to describe population *;
   if NumConfirmed=. then NumConfirmed=0 ; 
   if NumProbable=. then NumProbable=0 ; 

   if NumConfDead=. then NumConfDead=0 ; 
   if NumProbDead=. then NumProbDead=0 ; 

   * create total vars *;
   TotalCases = NumProbable + NumConfirmed ;
   TotalDead  = NumProbDead + NumConfDead ;

   if ReportedDate > '05APR22'd then DELETE;                               * <-- CHANGE DATE HERE ;
run;
/*   PROC print data= Colorado_County_dates; where CountyAssigned =''; run;*/
   PROC contents data=Colorado_County_dates varnum ;  title1 'Colorado_County_dates';  run;



*** Check numbers ***;
***---------------***;

* Starting dataset (Patient level) *;
   PROC freq data= CO_county_cases ;  tables CountyAssigned * (CaseStatus  Outcome) / nopercent norow nocol ;  run;

 * Reduced dataset (Date level) *;
  PROC means data= Colorado_County_dates  sum maxdec=0;
      var  NumProbable  NumConfirmed  TotalDead ;
      class CountyAssigned;
run;



***  Calculate Cumulatitive values and totals  ***;
***--------------------------------------------***;

Data County_Cases_stats; set Colorado_County_dates;
   by CountyAssigned ;

* Reset accumulator vars to 0 for each County *;
   if first.CountyAssigned then DO;  CumConfirmed=0;  CumProbable=0;  CumConfDead=0;  CumProbDead=0;   END;

* calculate cumulative counts *;
   CumConfirmed + NumConfirmed;
   CumProbable + NumProbable;
   CumConfDead + NumConfDead;
   CumProbDead + NumProbDead;

* create total vars for cumulative counts *;
   TotalCumCases = CumProbable + CumConfirmed ;
   TotalCumDead = CumProbDead + CumConfDead ;

* calculate daily changes *;
   DailyChangeCases = TotalCumCases - lag(TotalCumCases); 
   DailyChangeDead = TotalCumDead - lag(TotalCumDead);
run;



***  FINAL dataset  ***;
***-----------------***;

 ** Sort dataset **;
   PROC sort data=Colorado_County_dates
               out=Colorado_County_dates_sort ;
      by countyFIPS  ReportedDate ;
run;

** Need to re-order variables to match column headers in Template **;
DATA Colo_County_06APR2022;                                                                   * <-- CHANGE DATE HERE ;
   retain countyFIPS  county  StateAbbr  StateFIPS   ReportedDate  TotalCases  TotalDead  ;    
   set Colorado_County_dates_sort;

   Label
      ReportedDate = 'date'
      TotalCases = 'confirmed'
      TotalDead = 'deaths'  ;

   KEEP  countyFIPS  county  StateAbbr  StateFIPS   ReportedDate  TotalCases  TotalDead  ;
run;

   PROC contents data= Colo_County_06APR2022  varnum;  run;                                  * <-- CHANGE DATE HERE ;



***  Evaluate outcome  ***;
***--------------------***;

title;
   PROC means data= Colo_County_06APR2022  sum maxdec=0;                                     * <-- CHANGE DATE HERE ;
      var   TotalCases  TotalDead;
   title1; title2 'Final counts';
run;

/*   PROC print data= Colo_County_06APR2022 l;                                                 * <-- CHANGE DATE HERE ;*/
/*      where ReportedDate ge '01MAR20'd;*/
/*      sum  TotalCases  TotalDead  ;*/
/*run;*/



***  Export final dataset to Excel workbook  ***;
***------------------------------------------***;
                                                                                           * vvv  CHANGE DATE HERE  vvv ;
PROC EXPORT DATA= WORK.Colo_County_06APR2022 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\28.CDC case counts\Output\Colo_County_06APR2022.xlsx" 
            DBMS=EXCEL LABEL REPLACE;
     SHEET="Jurisdictional Aggregate Data"; 
RUN;












*** extra, leftover code ***;

   proc print data= Cases_County_stats ;
      id countyFIPS ; var county  stateAbbr stateFIPS  ReportedDate  NumConfirmed  NumConfDead ; 
/*      id CountyAssigned; var  county  StateAbbr  StateFIPS  County_FIPS countyFIPS  ;*/
run;


   proc sort data= Cases_County_stats
               out= Colorado_County_data_040122;
      by countyFIPS;
run;
   proc print data= Colorado_County_data_040122 ;
      id countyFIPS; var  county  StateAbbr  StateFIPS   ReportedDate  NumConfirmed  NumConfDead   ;
run;


