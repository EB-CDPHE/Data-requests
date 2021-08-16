/**********************************************************************************************
PROGRAM:  RFI.Pediatric_case_rates_DOUGLAS.sas
AUTHOR:   Eric Bush
CREATED:  August 13, 2021
MODIFIED:	
PURPOSE:	 RFI on pediatric case rates (7 d avg) by age group for Douglas county
INPUT:		COVID.CEDRS_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

***-------------------------***;
***  COUNTIES = Douglas  ***;
***-------------------------***;

***  Age group:  0-5 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'DOUGLAS' ;   var Yrs0_5 ;   run;

   %Let agepopulation = 21886 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Douglas0_5; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'DOUGLAS'  AND  (0 le  Age_at_Reported  < 6);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Douglas0_5  out= Douglas0_5_sort; by ReportedDate;
/*   proc print data= Douglas0_5_sort ;  ID ReportedDate ;  run;*/


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data Douglas0_5_rate; set Douglas0_5_sort;
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
   proc print data= Douglas0_5_rate ;  ID ReportedDate ;  run;


** add ALL reported dates for populations with sparse data **;
Data Douglas0_5_dates; merge Timeline  Douglas0_5_rate;
   by ReportedDate;

   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Douglas';  Ages='0-5 yo';
run;
   proc print data= Douglas0_5_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=Douglas0_5_dates   out=Douglas0_5_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Douglas0_5_MoveAv;
run;



***  Age group:  6-11 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'DOUGLAS' ;   var Yrs6_11 ;   run;

   %Let agepopulation = 25555 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Douglas6_11; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'DOUGLAS'  AND  (6 le  Age_at_Reported  < 12);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Douglas6_11  out= Douglas6_11_sort; by ReportedDate;
   proc print data= Douglas6_11_sort ;  ID ReportedDate ;  run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Douglas6_11_rate; set Douglas6_11_sort;
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
   proc print data= Douglas6_11_rate ;  ID ReportedDate ;  run;

** add ALL reported dates for populations with sparse data **;
Data Douglas6_11_dates; merge Timeline  Douglas6_11_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Douglas';  Ages='6-11 yo';
run;
   proc print data= Douglas6_11_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=Douglas6_11_dates   out=Douglas6_11_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Douglas6_11_MoveAv;
run;



***  Age group:  12-17 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'DOUGLAS' ;   var Yrs12_17 ;   run;

   %Let agepopulation = 34535 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Douglas12_17; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'DOUGLAS'  AND  (12 le  Age_at_Reported < 18);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Douglas12_17  out= Douglas12_17_sort; by ReportedDate;
/*   proc print data= Douglas12_17_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Douglas12_17_rate; set Douglas12_17_sort;
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
/*   proc print data= Douglas12_17_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Douglas12_17_dates; merge Timeline  Douglas12_17_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Douglas';  Ages='12-17 yo';
run;
/*   proc print data= Douglas12_17_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Douglas12_17_dates   out=Douglas12_17_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Douglas12_17_MoveAv;
run;



***  Age group:  18-115 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'DOUGLAS' ;   var Yrs18_121 ;   run;

   %Let agepopulation = 269550 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Douglas18_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'DOUGLAS'  AND  (18 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Douglas18_115  out= Douglas18_115_sort; by ReportedDate;
/*   proc print data= Douglas18_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Douglas18_115_rate; set Douglas18_115_sort;
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
/*   proc print data= Douglas18_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Douglas18_115_dates; merge Timeline  Douglas18_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Douglas';  Ages='18-115 yo';
run;
/*   proc print data= Douglas18_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Douglas18_115_dates   out=Douglas18_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Douglas18_115_MoveAv;
run;



***  Age group:  ALL ages  ***;
***------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'DOUGLAS' ;   var County_Population_Est ;   run;

   %Let agepopulation = 351526 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Douglas0_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'DOUGLAS' ;* AND  (0 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Douglas0_115  out= Douglas0_115_sort; by ReportedDate;
/*   proc print data= Douglas0_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Douglas0_115_rate; set Douglas0_115_sort;
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
/*   proc print data= Douglas0_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Douglas0_115_dates; merge Timeline  Douglas0_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Douglas';  Ages='0-115 yo';
run;
/*   proc print data= Douglas0_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Douglas0_115_dates   out=Douglas0_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Douglas0_115_MoveAv;
run;
