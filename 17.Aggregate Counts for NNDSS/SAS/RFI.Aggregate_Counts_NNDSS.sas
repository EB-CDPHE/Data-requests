/**********************************************************************************************
PROGRAM:  RFI.Aggregate_Counts_NNDSS.sas
AUTHOR:   Eric Bush
CREATED:  October 22, 2021
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;


***  Create MMWR weeks for 2020  ***;
***------------------------------***;


DATA MMWRweek;
   ReportedDate='29DEC19'd;
   MMWR_week_2020 = 1;
   output;
   do m = 1 to 371;
      ReportedDate+1;
      if mod(m,7)=0 then MMWR_week_2020+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop m ;
run;
proc print data= MMWRweek;  run;





*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA NNDSS_data;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL' ;
   Keep ProfileID EventID  CountyAssigned County  ReportedDate  CaseStatus  Outcome  
        Gender race ethnicity  Age_at_Reported  ;
run;

   PROC contents data=NNDSS_data  varnum; title1 'NNDSS_data'; run;

/*-------------------*
 | FINDINGS:         |
 | N = 701,892 obs   |
 *-------------------*/


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

 Data DateCheck; set NNDSS_data;
   Day_of_week = put(ReportedDate, DOWname9.);
   Week_of_year = put(ReportedDate, WeekU5.);
   YYweek = put(ReportedDate, YYWeekU5.);
run;
/*proc freq data=datecheck; tables Day_of_week; run;*/

proc freq data=datecheck; 
tables WeekW_of_year * Day_of_week * ReportedDate / list; 
run;



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
tables MMWR_week_2020 * ReportedDate / list; 
run;
