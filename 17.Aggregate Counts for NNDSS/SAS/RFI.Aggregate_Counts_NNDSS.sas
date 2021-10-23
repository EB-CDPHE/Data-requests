/**********************************************************************************************
PROGRAM:  RFI.Aggregate_Counts_NNDSS.sas
AUTHOR:   Eric Bush
CREATED:  October 15, 2021
MODIFIED: 102321: Put copy of dataset used to generate aggregate numbers into RFI folder
          102221: Added Race format to combine "Multiple" and "Other"
          101821: Finished / finalized work. 
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
/*proc print data= MMWRweek;  run;*/



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
      label CaseStatus = 'Case Status';
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
title2 'MMWR Month';
   PROC freq data=NNDSS_dates ;
      table CaseStatus * MMWR_20week /nopercent norow nocol ;
      format MMWR_20week MMWR_Month.;
      label CaseStatus  = 'Case Status'
            MMWR_20week = 'MMWR weeks grouped by month' ;
run;



/*----------------------------------------------------------------------------------------------*
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
 *----------------------------------------------------------------------------------------------*/

    PROC format;
     value Age8cat
           0-<1  = '< 1 '
           1-<5  = '1-4 '
          5-<15  = '5-14 '
         15-<25  = '15-24 '
         25-<40  = '25-39 '
         40-<65  = '40-64 '
         65-<121 = '65-120 '
         ., 121  = 'Unknown' ;
run;

title1 'Data source: CEDRS_view --> NNDSS_dates';
title2 'Age Group';
   PROC freq data=NNDSS_dates ;
      table  CaseStatus * Age_at_Reported / missing missprint nopercent norow nocol;
      format Age_at_Reported Age8Cat. ; 
      label CaseStatus  = 'Case Status'
            Age_at_Reported = 'Age in years' ;
run;



/*------------------------------------------------------------------------------------------*
 | SEX (Gender):
 | "For confirmed and probable COVID-19 cases individually, 
 |  enter the total number of 2020 COVID-19 cases among U.S. residents 
 |  for the specified sex categories, including the number of cases where sex is unknown."
 |
 | Gender = 
 |   Female
 |   Male
 |   Sex unknown or missing
*------------------------------------------------------------------------------------------*/

   PROC format;
      value $ GenderFmt
         'Female' = 'Female'
         'Male' = 'Male'
         other = 'Other' ;
run;

title1 'Data source: CEDRS_view --> NNDSS_dates';
title2 'Sex (Gender)';
   PROC freq data=NNDSS_dates order=freq;
      table  CaseStatus * Gender / missing missprint nopercent norow nocol;
      format Gender $GenderFmt. ; 
      label CaseStatus  = 'Case Status'
            Gender = 'Gender' ;
run;



/*---------------------------------------------------------------------------------------------*
 | RACE and ETHNICITY:
 | "For confirmed and probable COVID-19 cases, enter the total number of 2020 COVID-19 cases
 |  among U.S. residents for the specified race/ethnicity categories listed below, 
 |  including the number of cases where race/ethnicity is unknown or missing."
 |
 | Race and Ethnicity combinations are: 
 |   Hispanic/Latino and (Native American or Alaska Native)
 |   Hispanic/Latino and (Black or African American)
 |   Hispanic/Latino and White
 |   Hispanic/Latino and Asian
 |   Hispanic/Latino and (Native Hawaiian or other Pacific Islander)
 |   Hispanic/Latino and (Other or multi-race)
 |   Hispanic/Latino and unknown/missing race 
 |
 |   Non-Hispanic/Latino and (Native American or Alaska Native)
 |   Non-Hispanic/Latino and (Black or African American)
 |   Non-Hispanic/Latino and White
 |   Non-Hispanic/Latino and Asian
 |   Non-Hispanic/Latino and (Native Hawaiian or other Pacific Islander)
 |   Non-Hispanic/Latino and (Other or multi-race)
 |   Non-Hispanic/Latino and unknown/missing race
 *-------------------------------------------------------------------------------------------*/

   PROC format;
      value $ RaceFmt
         'Multiple','Other' = 'Multiple/Other' ;
run;

title1 'Data source: CEDRS_view --> NNDSS_dates';
title2 'Race and Ethnicity';

   PROC freq data= NNDSS_data   ;
      where CaseStatus = 'confirmed';
      table Ethnicity * Race   / list missing missprint ;
      format Race $RaceFmt. ;
title3 "CaseStatus = 'confirmed'";
run;

   PROC freq data= NNDSS_data   ;
      where CaseStatus = 'probable';
      table Ethnicity * Race   / list missing missprint ;
      format Race $RaceFmt. ;
title3 "CaseStatus = 'probable'";
run;

title;


***  Store dataset that generated FINAL numbers  ***;
***----------------------------------------------***;

libname RFI 'C:\Users\eabush\Documents\GitHub\Data-requests\17.Aggregate Counts for NNDSS\Output data'; run;

DATA RFI.NNDSS_data; set NNDSS_data;
run;
