/**********************************************************************************************
PROGRAM:  RFI.Pediatric_case_rates_ADAMS.sas
AUTHOR:   Eric Bush
CREATED:  August 13, 2021
MODIFIED:	
PURPOSE:	 RFI on pediatric case rates (7 d avg) by age group for Adamserson county
INPUT:		COVID.CEDRS_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

***-------------------------***;
***  COUNTIES = Adams  ***;
***-------------------------***;

***  Age group:  0-5 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'ADAMS' ;   var Yrs0_5 ;   run;

   %Let agepopulation = 42256 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Adams0_5; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'ADAMS'  AND  (0 le  Age_at_Reported  < 6);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Adams0_5  out= Adams0_5_sort; by ReportedDate;
/*   proc print data= Adams0_5_sort ;  ID ReportedDate ;  run;*/


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data Adams0_5_rate; set Adams0_5_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then NumCases=0;
   NumCases+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County;
run;
   proc print data= Adams0_5_rate ;  ID ReportedDate ;  run;


** add ALL reported dates for populations with sparse data **;
Data Adams0_5_dates; merge Timeline  Adams0_5_rate;
   by ReportedDate;

   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Adams';  Ages='0-5 yo';
run;
   proc print data= Adams0_5_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=Adams0_5_dates   out=Adams0_5_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Adams0_5_MoveAv;
run;



***  Age group:  6-11 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'ADAMS' ;   var Yrs6_11 ;   run;

   %Let agepopulation = 43689 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Adams6_11; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'ADAMS'  AND  (6 le  Age_at_Reported  < 12);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Adams6_11  out= Adams6_11_sort; by ReportedDate;
   proc print data= Adams6_11_sort ;  ID ReportedDate ;  run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Adams6_11_rate; set Adams6_11_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then NumCases=0;
   NumCases+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County;
run;
   proc print data= Adams6_11_rate ;  ID ReportedDate ;  run;

** add ALL reported dates for populations with sparse data **;
Data Adams6_11_dates; merge Timeline  Adams6_11_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Adams';  Ages='6-11 yo';
run;
   proc print data= Adams6_11_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=Adams6_11_dates   out=Adams6_11_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Adams6_11_MoveAv;
run;



***  Age group:  12-17 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'ADAMS' ;   var Yrs12_17 ;   run;

   %Let agepopulation = 46368 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Adams12_17; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'ADAMS'  AND  (12 le  Age_at_Reported < 18);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Adams12_17  out= Adams12_17_sort; by ReportedDate;
/*   proc print data= Adams12_17_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Adams12_17_rate; set Adams12_17_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then NumCases=0;
   NumCases+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County;
run;
/*   proc print data= Adams12_17_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Adams12_17_dates; merge Timeline  Adams12_17_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Adams';  Ages='12-17 yo';
run;
/*   proc print data= Adams12_17_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Adams12_17_dates   out=Adams12_17_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Adams12_17_MoveAv;
run;



***  Age group:  18-115 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'ADAMS' ;   var Yrs18_121 ;   run;

   %Let agepopulation = 385568 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Adams18_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'ADAMS'  AND  (18 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Adams18_115  out= Adams18_115_sort; by ReportedDate;
/*   proc print data= Adams18_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Adams18_115_rate; set Adams18_115_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then NumCases=0;
   NumCases+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County;
run;
/*   proc print data= Adams18_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Adams18_115_dates; merge Timeline  Adams18_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Adams';  Ages='18-115 yo';
run;
/*   proc print data= Adams18_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Adams18_115_dates   out=Adams18_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Adams18_115_MoveAv;
run;



***  Age group:  ALL ages  ***;
***------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'ADAMS' ;   var County_Population_Est ;   run;

   %Let agepopulation = 517881 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Adams0_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'ADAMS' ;* AND  (0 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Adams0_115  out= Adams0_115_sort; by ReportedDate;
/*   proc print data= Adams0_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Adams0_115_rate; set Adams0_115_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then NumCases=0;
   NumCases+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County;
run;
/*   proc print data= Adams0_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Adams0_115_dates; merge Timeline  Adams0_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Adams';  Ages='0-115 yo';
run;
/*   proc print data= Adams0_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Adams0_115_dates   out=Adams0_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Adams0_115_MoveAv;
run;
