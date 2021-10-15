/**********************************************************************************************
PROGRAM:  RFI.US_vs_CO.sas
AUTHOR:   Eric Bush
CREATED:  September 20, 2021
MODIFIED:	
PURPOSE:	 RFI on creating chart that compares case rate (7d mov avg) for US vs CO
INPUT:		
OUTPUT:		
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

TITLE;
OPTIONS pageno=1;


** Import JHU Global data and keep US only **;

PROC IMPORT OUT= WORK.JHUdata 
            DATAFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\CO vs national case rates\John Hopkins data\US_cases_JH.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


PROC contents data=JHUdata  varnum ; title1 'JHUdata'; run;

** check total number of cases in USA **;
PROC means data= JHUdata sum maxdec=0; 
   var Cases;
run;

** restrict date range to begin March 1, 2020 **;
   PROC means data= JHUdata n nmiss ; 
      where Date ge '01MAR20'd; 
run;



***  USA case rate  ***;
***-----------------***;

** Set population for age group **;
   %Let Census2020_pop = 331449281 ;      * <-- pull number from census.gov ;

**  USA case dataset and sort by date  **;
 Data USA_cases; set JHUdata ;
      where Date ge '01MAR20'd; 
      rename Date = ReportedDate;
run;
   proc print data= USA_cases ;  ID ReportedDate ;  run;

**  Calculate case rate  **;
Data USA_CaseRate;  length State $ 13 ;  set USA_cases;
   CaseRate = Cases / (&Census2020_pop/100000);
   State='ALL US States';  
run;
/*   proc print data= USA_CaseRate ;  ID ReportedDate ;  run;*/

**  Calculate 7-day moving averages  **;
   PROC expand data=USA_CaseRate   out=USA_MoveAv  method=none;
      id ReportedDate;
      convert Cases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
/*   PROC print data= USA_MoveAv;  run;*/



***  Colorado case rate  ***;
***----------------------***;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

** Set population for age group **;
   %Let Census2020_pop = 5773714 ;      * <-- pull number from census.gov ;

**  Colorado case dataset and sort by date  **;
 Data Colorado0_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  (0 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
   PROC sort data=Colorado0_115  
              out= Colorado0_115_sort; 
      by ReportedDate;
run;
/*   proc print data= Colorado0_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Colorado0_115_rate; set Colorado0_115_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then NumCases=0;
   NumCases+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&Census2020_pop/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County;
run;
/*   proc print data= Colorado0_115_rate ;  ID ReportedDate ;  run;*/


*** Create timeline of all dates ***;
DATA timeline;
   ReportedDate='01MAR20'd;
   output;
   do t = 1 to 560;
      ReportedDate+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop t ;
run;
/*proc print data= timeline;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Colorado0_115_dates;  length State $ 13 ;   merge Timeline  Colorado0_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   State='Colorado';  
run;
/*   proc print data= Colorado0_115_dates ;  ID ReportedDate ;  run;*/

**  Calculate 7-day moving averages  **;
   PROC expand data=Colorado0_115_dates   out=Colorado_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
/*   PROC print data= Colorado_MoveAv;  run;*/



***  Combine datasets for charting  ***;
***---------------------------------***;

DATA US_vs_CO; set  USA_MoveAv  Colorado_MoveAv  ;
run;

   PROC contents data= US_vs_CO varnum; title1 'US_vs_CO'; run;


/*PROC EXPORT DATA= US_vs_CO */
/*            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\CO vs national case rates\US_vs_CO.xls" */
/*            DBMS=EXCEL REPLACE;*/
/*     SHEET="data"; */
/*RUN;*/


libname RFIUSA 'C:\Users\eabush\Documents\GitHub\Data-requests\CO vs national case rates' ; run;
DATA RFIUSA.US_vs_CO ; set US_vs_CO; 
run;
