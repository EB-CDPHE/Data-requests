/**********************************************************************************************
PROGRAM:  RFI.Pediatric_case_rates_BROOMFIELD.sas
AUTHOR:   Eric Bush
CREATED:  August 13, 2021
MODIFIED:	
PURPOSE:	 RFI on pediatric case rates (7 d avg) by age group for BROOMFIELD county
INPUT:		COVID.CEDRS_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

***-------------------------***;
***  COUNTIES = Broomfield  ***;
***-------------------------***;

***  Age group:  0-5 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BROOMFIELD' ;   var Yrs0_5 ;   run;

   %Let agepopulation = 4426 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Broomfield0_5; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BROOMFIELD'  AND  (0 le  Age_at_Reported  < 6);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Broomfield0_5  out= Broomfield0_5_sort; by ReportedDate;
/*   proc print data= Broomfield0_5_sort ;  ID ReportedDate ;  run;*/


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data Broomfield0_5_rate; set Broomfield0_5_sort;
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
/*   proc print data= Broomfield0_5_rate ;  ID ReportedDate ;  run;*/


** add ALL reported dates for populations with sparse data **;
Data Broomfield0_5_dates; merge Timeline  Broomfield0_5_rate;
   by ReportedDate;

   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Broomfield';  Ages='0-5 yo';
run;
/*   proc print data= Broomfield0_5_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Broomfield0_5_dates   out=Broomfield0_5_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Broomfield0_5_MoveAv;
run;



***  Age group:  6-11 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BROOMFIELD' ;   var Yrs6_11 ;   run;

   %Let agepopulation = 5075 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Broomfield6_11; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BROOMFIELD'  AND  (6 le  Age_at_Reported  < 12);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Broomfield6_11  out= Broomfield6_11_sort; by ReportedDate;
/*   proc print data= Broomfield6_11_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Broomfield6_11_rate; set Broomfield6_11_sort;
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
/*   proc print data= Broomfield6_11_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Broomfield6_11_dates; merge Timeline  Broomfield6_11_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Broomfield';  Ages='6-11 yo';
run;
/*   proc print data= Broomfield6_11_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Broomfield6_11_dates   out=Broomfield6_11_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Broomfield6_11_MoveAv;
run;



***  Age group:  12-17 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BROOMFIELD' ;   var Yrs12_17 ;   run;

   %Let agepopulation = 5966 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Broomfield12_17; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BROOMFIELD'  AND  (12 le  Age_at_Reported < 18);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Broomfield12_17  out= Broomfield12_17_sort; by ReportedDate;
/*   proc print data= Broomfield12_17_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Broomfield12_17_rate; set Broomfield12_17_sort;
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
/*   proc print data= Broomfield12_17_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Broomfield12_17_dates; merge Timeline  Broomfield12_17_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Broomfield';  Ages='12-17 yo';
run;
/*   proc print data= Broomfield12_17_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Broomfield12_17_dates   out=Broomfield12_17_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Broomfield12_17_MoveAv;
run;



***  Age group:  18-115 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BROOMFIELD' ;   var Yrs18_121 ;   run;

   %Let agepopulation = 55296 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Broomfield18_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BROOMFIELD'  AND  (18 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Broomfield18_115  out= Broomfield18_115_sort; by ReportedDate;
/*   proc print data= Broomfield18_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Broomfield18_115_rate; set Broomfield18_115_sort;
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
/*   proc print data= Broomfield18_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Broomfield18_115_dates; merge Timeline  Broomfield18_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Broomfield';  Ages='18-115 yo';
run;
/*   proc print data= Broomfield18_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Broomfield18_115_dates   out=Broomfield18_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Broomfield18_115_MoveAv;
run;



***  Age group:  ALL ages  ***;
***------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BROOMFIELD' ;   var County_Population_Est ;   run;

   %Let agepopulation = 70763 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Broomfield0_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BROOMFIELD' ;* AND  (0 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Broomfield0_115  out= Broomfield0_115_sort; by ReportedDate;
/*   proc print data= Broomfield0_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Broomfield0_115_rate; set Broomfield0_115_sort;
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
/*   proc print data= Broomfield0_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Broomfield0_115_dates; merge Timeline  Broomfield0_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='Broomfield';  Ages='0-115 yo';
run;
/*   proc print data= Broomfield0_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Broomfield0_115_dates   out=Broomfield0_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Broomfield0_115_MoveAv;
run;
