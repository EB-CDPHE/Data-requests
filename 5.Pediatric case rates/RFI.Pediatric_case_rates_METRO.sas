/**********************************************************************************************
PROGRAM:  RFI.Pediatric_case_rates_Metro.sas
AUTHOR:   Eric Bush
CREATED:  August 13, 2021
MODIFIED:	
PURPOSE:	 RFI on pediatric case rates (7 d avg) by age group for Metro county
INPUT:		COVID.CEDRS_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

***-------------------------***;
***  COUNTIES = Metro  ***;
***-------------------------***;

***  Age group:  0-5 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE' 
                       'BOULDER', 'BROOMFIELD', 'DOUGLAS') ;   
      var Yrs0_5 ;   
run;

   %Let agepopulation = 220763 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Metro0_5; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE', 'BOULDER', 'BROOMFIELD', 'DOUGLAS' )  
      AND  (0 le  Age_at_Reported  < 6);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Metro0_5  out= Metro0_5_sort; by ReportedDate;
/*   proc print data= Metro0_5_sort ;  ID ReportedDate ;  run;*/


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data Metro0_5_rate; set Metro0_5_sort;
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
   proc print data= Metro0_5_rate ;  ID ReportedDate ;  run;


** add ALL reported dates for populations with sparse data **;
Data Metro0_5_dates; merge Timeline  Metro0_5_rate;
   by ReportedDate;

   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Metro';  Ages='0-5 yo';
run;
   proc print data= Metro0_5_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=Metro0_5_dates   out=Metro0_5_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Metro0_5_MoveAv;
run;



***  Age group:  6-11 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE' 
                       'BOULDER', 'BROOMFIELD', 'DOUGLAS') ;   
      var Yrs6_11 ;   
run;

   %Let agepopulation = 229192 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Metro6_11; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE', 'BOULDER', 'BROOMFIELD', 'DOUGLAS' )  
      AND  (6 le  Age_at_Reported  < 12);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Metro6_11  out= Metro6_11_sort; by ReportedDate;
   proc print data= Metro6_11_sort ;  ID ReportedDate ;  run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Metro6_11_rate; set Metro6_11_sort;
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
   proc print data= Metro6_11_rate ;  ID ReportedDate ;  run;

** add ALL reported dates for populations with sparse data **;
Data Metro6_11_dates; merge Timeline  Metro6_11_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Metro';  Ages='6-11 yo';
run;
   proc print data= Metro6_11_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=Metro6_11_dates   out=Metro6_11_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Metro6_11_MoveAv;
run;



***  Age group:  12-17 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE' 
                       'BOULDER', 'BROOMFIELD', 'DOUGLAS') ;   
      var Yrs12_17 ;   
run;

   %Let agepopulation = 248406 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Metro12_17; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE', 'BOULDER', 'BROOMFIELD', 'DOUGLAS' )  
      AND  (12 le  Age_at_Reported < 18);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Metro12_17  out= Metro12_17_sort; by ReportedDate;
/*   proc print data= Metro12_17_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Metro12_17_rate; set Metro12_17_sort;
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
/*   proc print data= Metro12_17_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Metro12_17_dates; merge Timeline  Metro12_17_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Metro';  Ages='12-17 yo';
run;
/*   proc print data= Metro12_17_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Metro12_17_dates   out=Metro12_17_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Metro12_17_MoveAv;
run;



***  Age group:  18-115 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE' 
                       'BOULDER', 'BROOMFIELD', 'DOUGLAS') ;   
      var Yrs18_121 ;   
run;

   %Let agepopulation = 2538115 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Metro18_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE', 'BOULDER', 'BROOMFIELD', 'DOUGLAS' )  
      AND  (18 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Metro18_115  out= Metro18_115_sort; by ReportedDate;
/*   proc print data= Metro18_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Metro18_115_rate; set Metro18_115_sort;
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
/*   proc print data= Metro18_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Metro18_115_dates; merge Timeline  Metro18_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Metro';  Ages='18-115 yo';
run;
/*   proc print data= Metro18_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Metro18_115_dates   out=Metro18_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Metro18_115_MoveAv;
run;



***  Age group:  ALL ages  ***;
***------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE' 
                       'BOULDER', 'BROOMFIELD', 'DOUGLAS') ;   
      var County_Population_Est ;   
run;

   %Let agepopulation = 3236476 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Metro0_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('DENVER' ,'JEFFERSON' ,'ADAMS' ,'ARAPAHOE', 'BOULDER', 'BROOMFIELD', 'DOUGLAS' )  ;
   * AND  (0 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Metro0_115  out= Metro0_115_sort; by ReportedDate;
/*   proc print data= Metro0_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Metro0_115_rate; set Metro0_115_sort;
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
/*   proc print data= Metro0_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Metro0_115_dates; merge Timeline  Metro0_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Metro';  Ages='0-115 yo';
run;
/*   proc print data= Metro0_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Metro0_115_dates   out=Metro0_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Metro0_115_MoveAv;
run;
