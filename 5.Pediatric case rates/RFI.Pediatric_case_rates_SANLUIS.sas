/**********************************************************************************************
PROGRAM:  RFI.Pediatric_case_rates_SanLuis.sas
AUTHOR:   Eric Bush
CREATED:  August 13, 2021
MODIFIED:	
PURPOSE:	 RFI on pediatric case rates (7 d avg) by age group for San Luis region
INPUT:		COVID.CEDRS_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

***-------------------------***;
***  COUNTIES = SanLuis  ***;
***-------------------------***;

***  Age group:  0-5 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS') ;   
      var Yrs0_5 ;   
run;

   %Let agepopulation = 3381 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data SanLuis0_5; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS' )  
      AND  (0 le  Age_at_Reported  < 6);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=SanLuis0_5  out= SanLuis0_5_sort; by ReportedDate;
/*   proc print data= SanLuis0_5_sort ;  ID ReportedDate ;  run;*/


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data SanLuis0_5_rate; set SanLuis0_5_sort;
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
   proc print data= SanLuis0_5_rate ;  ID ReportedDate ;  run;


** add ALL reported dates for populations with sparse data **;
Data SanLuis0_5_dates; merge Timeline  SanLuis0_5_rate;
   by ReportedDate;

   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='San Luis region';  Ages='0-5 yo';
run;
   proc print data= SanLuis0_5_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=SanLuis0_5_dates   out=SanLuis0_5_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= SanLuis0_5_MoveAv;
run;



***  Age group:  6-11 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS') ;   
      var Yrs6_11 ;   
run;

   %Let agepopulation = 3948 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data SanLuis6_11; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS' )  
      AND  (6 le  Age_at_Reported  < 12);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=SanLuis6_11  out= SanLuis6_11_sort; by ReportedDate;
   proc print data= SanLuis6_11_sort ;  ID ReportedDate ;  run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data SanLuis6_11_rate; set SanLuis6_11_sort;
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
   proc print data= SanLuis6_11_rate ;  ID ReportedDate ;  run;

** add ALL reported dates for populations with sparse data **;
Data SanLuis6_11_dates; merge Timeline  SanLuis6_11_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='San Luis region';  Ages='6-11 yo';
run;
   proc print data= SanLuis6_11_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=SanLuis6_11_dates   out=SanLuis6_11_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= SanLuis6_11_MoveAv;
run;



***  Age group:  12-17 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS') ;   
      var Yrs12_17 ;   
run;

   %Let agepopulation = 3933 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data SanLuis12_17; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS' )  
      AND  (12 le  Age_at_Reported < 18);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=SanLuis12_17  out= SanLuis12_17_sort; by ReportedDate;
/*   proc print data= SanLuis12_17_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data SanLuis12_17_rate; set SanLuis12_17_sort;
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
/*   proc print data= SanLuis12_17_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data SanLuis12_17_dates; merge Timeline  SanLuis12_17_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='San Luis region';  Ages='12-17 yo';
run;
/*   proc print data= SanLuis12_17_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=SanLuis12_17_dates   out=SanLuis12_17_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= SanLuis12_17_MoveAv;
run;



***  Age group:  18-115 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS') ;   
      var Yrs18_121 ;   
run;

   %Let agepopulation = 35777 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data SanLuis18_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS' )  
      AND  (18 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=SanLuis18_115  out= SanLuis18_115_sort; by ReportedDate;
/*   proc print data= SanLuis18_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data SanLuis18_115_rate; set SanLuis18_115_sort;
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
/*   proc print data= SanLuis18_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data SanLuis18_115_dates; merge Timeline  SanLuis18_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='San Luis region';  Ages='18-115 yo';
run;
/*   proc print data= SanLuis18_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=SanLuis18_115_dates   out=SanLuis18_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= SanLuis18_115_MoveAv;
run;



***  Age group:  ALL ages  ***;
***------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   
      where County in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS') ;   
      var County_Population_Est ;   
run;

   %Let agepopulation = 47039 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data SanLuis0_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned in ('COSTILLA' ,'MINERAL' ,'ALAMOSA' ,'SAGUACHE', 'RIO GRANDE', 'CONEJOS' )  ;
   * AND  (0 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=SanLuis0_115  out= SanLuis0_115_sort; by ReportedDate;
/*   proc print data= SanLuis0_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data SanLuis0_115_rate; set SanLuis0_115_sort;
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
/*   proc print data= SanLuis0_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data SanLuis0_115_dates; merge Timeline  SanLuis0_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='SanLuis';  Ages='0-115 yo';
run;
/*   proc print data= SanLuis0_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=SanLuis0_115_dates   out=SanLuis0_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= SanLuis0_115_MoveAv;
run;
