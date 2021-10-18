/**********************************************************************************************
PROGRAM:  RFI.Aggregate_Counts_NNDSS.sas
AUTHOR:   Eric Bush
CREATED:  October 22, 2021
MODIFIED:	
PURPOSE:	 Create summary output for NNDSS spreadsheet for requested aggregated data
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;


***  Create MMWR weeks for 2020  ***;
***------------------------------***;


DATA MMWRweek;
   ReportedDate='29DEC19'd;
   MMWR_20week = 1;
   output;
   do m = 1 to 371;
      ReportedDate+1;
      if mod(m,7)=0 then MMWR_20week+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop m ;
run;
proc print data= MMWRweek;  run;





*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA NNDSS_data;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  ('29DEC19'd le ReportedDate le '02JAN21'd);
   Keep ProfileID EventID  CountyAssigned County  ReportedDate  CaseStatus  Outcome  
        Gender race ethnicity  Age_at_Reported  ;
run;

   PROC contents data=NNDSS_data  varnum; title1 'NNDSS_data'; run;

/*-------------------------------------------*
 | FINDINGS:                                 |
 | N = 710,142 obs from CEDRS_view           |
 | N = 353,960 obs in specified time period. |
 *-------------------------------------------*/


***  Check data  ***;
***--------------***;

*  How many distinct counties? (should be 64) *;
   PROC SQL;
      select count(distinct CountyAssigned) as NumCountyAssigned,
             count(distinct County) as NumCounty
      from NNDSS_data ;
run;
 
 *  How many distinct counties? (should be 64) *;
  PROC freq data= NNDSS_data  ;
      tables CountyAssigned  County  ;
      tables CountyAssigned * County / list ;
run;

* Case Status *;
  PROC freq data= NNDSS_data ;  tables CaseStatus ;  run;

* Outcome *;
  PROC freq data= NNDSS_data ;  tables Outcome ;  run;

* Gender *;
  PROC freq data= NNDSS_data ;  tables Gender ;  run;
  PROC freq data= NNDSS_data ;  tables Gender ; format Gender $GenderFmt. ;  run;

* Age *;
   PROC means data= NNDSS_data  n nmiss ;
      var Age_at_Reported ;
run;

   PROC univariate data= NNDSS_data ;  var Age_at_Reported ; run;

   PROC freq data= NNDSS_data ;  tables Age_at_Reported ; format Age_at_Reported $Age8Cat. ;  run;

* Reported Date *;
   PROC means data= NNDSS_data  n nmiss ;
      var ReportedDate ;
run;

   PROC freq data= NNDSS_data ;
      tables ReportedDate ;
      format ReportedDate WeekU5. ;
run;

/*----------------------------------------------------------------------------*
 |FINDINGS:
 | Though the WeekU format begins on Sunday and ends on Saturday, 
 | it does not align with prescribed dates for MMWR weeks.
 |FIX: Create MMWR_20week variable to define weeks based on ReportedDate,
 | then apply MMWR_Month format to group into MMWR months per request.
 *----------------------------------------------------------------------------*/

/* Data DateCheck; set NNDSS_data;*/
/*   Day_of_week = put(ReportedDate, DOWname9.);*/
/*   Week_of_year = put(ReportedDate, WeekU5.);*/
/*   YYweek = put(ReportedDate, YYWeekU5.);*/
/*run;*/
/*proc freq data=datecheck; tables Day_of_week; run;*/
/*proc freq data=datecheck; */
/*tables WeekW_of_year * Day_of_week * ReportedDate / list; */
/*run;*/



***  Merge MMWR_20week variable to NNDSS_data by ReportedDate  ***;
***------------------------------------------------------------***;

**  Create age specific dataset and sort by date  **;
  PROC sort data=NNDSS_data  
             out= NNDSS_data_sort; 
      by ReportedDate;
run;

Data NNDSS_dates;  merge MMWRweek  NNDSS_data_sort(in=x);
   by ReportedDate;
   if x;
run;


proc freq data=NNDSS_dates; 
/*tables MMWR_20week * ReportedDate / list;       *  <-- to check that MMWR_20week is defined correctly *;*/
tables MMWR_20week ; 
format MMWR_20week MMWR_Month.;
run;



***  Requested Aggregated Data  ***;
***-----------------------------***;


/*--------------------------------------------------------------------------------*
 | TOTAL CASES:
 | "For confirmed and probable COVID-19 cases, enter the total number 
 | of 2020 COVID-19 cases among U.S. residents in your jurisdiction."
 |
 | * CaseStatus in ("confirmed", "probable").
 | * ReportedDate between ('29DEC19'd and '02JAN21'd), i.e. MMWR weeks 1-53
 | * County NOT = "International"
 *--------------------------------------------------------------------------------*/

title1 'Data source: CEDRS_view --> NNDSS_dates';
title2 'Total Cases';
   PROC freq data=NNDSS_dates ;
      table CaseStatus;
run;



/*-------------------------------------------------------------------------------------------------------------*
 | MONTH:
 | "For confirmed and probable COVID-19 cases, enter the total number of 2020 COVID-19 cases
 |  among U.S. residents, by month, including the number of cases where the month is unknown 
 |  or missing.  Month is defined by Morbidity and Mortality Weekly Report (MMWR) weeks"
 |
 | * MMWR week 1 for 2020 = Sunday, December 29, 2019 to Saturday, January 4, 2021.
 | 
 | January = MMWR weeks 1–4 (beginning Sunday, December 29, 2019, and ending Saturday, January 25, 2020)
 | February = MMWR weeks 5–9 (beginning Sunday, January 26, 2020, and ending Saturday, February 29, 2020)
 | March = MMWR weeks 10–13 (beginning Sunday, March 1, 2020, and ending Saturday, March 28, 2020)
 | April = MMWR weeks 14–17 (beginning Sunday, March 29, 2020, and ending Saturday, April 25, 2020)
 | May = MMWR weeks 18–22 (beginning Sunday, April 26, 2020, and ending Saturday, May 30, 2020)
 | June = MMWR weeks 23–26 (beginning Sunday, May 31, 2020, and ending Saturday, June 27, 2020)
 | July = MMWR weeks 27–30 (beginning Sunday, June 28, 2020, and ending Saturday, July 25, 2020)
 | August = MMWR weeks 31–35 (beginning Sunday, July 26, 2020, and ending Saturday, August 29, 2020)
 | September = MMWR weeks 36–39 (beginning Sunday, August 30, 2020, and ending Saturday, September 26, 2020)
 | October = MMWR weeks 40–44 (beginning Sunday, September 27, 2020, and ending Saturday, October 31, 2020)
 | November = MMWR weeks 45–48 (beginning Sunday, November 1, 2020, and ending Saturday, November 28, 2020)
 | December = MMWR weeks 49–53 (beginning Sunday, November 29, 2020, and ending Saturday, January 2, 2021)
 *--------------------------------------------------------------------------------------------------------------*/

    PROC format;
      value MMWR_Month
         1-4 = 'January'
         5-9 = 'February'
         10-13 = 'March'
         14-17 = 'April'
         18-22 = 'May'
         23-26 = 'June'
         27-30 = 'July'
         31-35 = 'August'
         36-39 = 'September'
         40-44 = 'October'
         45-48 = 'November'
         49-53 = 'December' ;
run;

title1 'Data source: CEDRS_view --> NNDSS_dates';
title2 'Month';
   PROC freq data=NNDSS_dates ;
      table CaseStatus * MMWR_20week /nopercent norow nocol ;
      format MMWR_20week MMWR_Month.;
run;



/*--------------------------------------------------------------------------------*
 | AGE GROUP:
 | "For confirmed and probable COVID-19 cases, enter the total number of 2020 COVID-19 cases
 |  among U.S. residents, by the specified age groups, including the number of cases where 
 |  age is unknown or missing."
 |
 | Requsested age groups are:
 | <1 year
 | 1-4 years
 | 5-14 years
 | 15-24 years
 | 25-39 years
 | 40-64 years
 | >=65 years
 | Age unknown or missing 
 *--------------------------------------------------------------------------------*/

    PROC format;
     value Age8cat
           0-<1  = '< 1 year'
           1-<5  = '1-4 years'
          5-<15  = '5-14 years'
         15-<25  = '15-24 years'
         25-<40  = '25-39 years'
         40-<65  = '40-64 years'
         65-<121 = '65-120 years'
         ., 121  = 'Unknown' ;
run;

title1 'Data source: CEDRS_view --> NNDSS_dates';
title2 'Age Group';
   PROC freq data=NNDSS_dates ;
      table  CaseStatus * Age_at_Reported / missing missprint nopercent norow nocol;
      format Age_at_Reported Age8Cat. ; 
run;


