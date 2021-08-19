/**********************************************************************************************
PROGRAM:  RFI.Pediatric_case_rates_COLORADO.sas
AUTHOR:   Eric Bush
CREATED:  August 13, 2021
MODIFIED:	
PURPOSE:	 RFI on pediatric case rates (7 d avg) by age group for Colorado county
INPUT:		COVID.CEDRS_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

   PROC contents data= COVID.CEDRS_view_fix varnum ; run;
   PROC freq data= COVID.CEDRS_view_fix ; 
/*tables CountyAssigned * County / list missing missprint ;*/
tables hospitalized  hospitalized_cophs hospitalized * hospitalized_cophs / list missing missprint ;
run;


***-------------------------***;
***  COUNTIES = ALL  ***;
***-------------------------***;

***  Age group:  0-5 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County ^= 'INTERNATIONAL' ;   var Yrs0_5 ;   run;

   %Let agepopulation = 395634 ;      * <-- pull number from county population;

proc freq data= COVID.CEDRS_view_fix ;
table CountyAssigned;
run;

**  Create age specific dataset and sort by date  **;
 Data Colorado0_5; set COVID.CEDRS_view_fix ;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  (0 le  Age_at_Reported  < 6);
   keep ProfileID EventID ReportedDate Age_at_Reported County hospitalized;
run;
  PROC sort data=Colorado0_5  out= Colorado0_5_sort; by ReportedDate;
/*   proc print data= Colorado0_5_sort ;  ID ReportedDate ;  run;*/


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data Colorado0_5_rate; set Colorado0_5_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then do; NumCases=0; NumHosp=0; end;
   NumCases+1; 
   if hospitalized=1 then NumHosp+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      HospRate= NumHosp / (&agepopulation/100000);
      PropHosp= (NumHosp / NumCases) * 100 ;
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County  hospitalized ;
run;
   proc print data= Colorado0_5_rate ;  ID ReportedDate ;  run;


** add ALL reported dates for populations with sparse data **;
Data Colorado0_5_dates; merge Timeline  Colorado0_5_rate;
   by ReportedDate;

   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   if NumHosp=.  then NumHosp=0 ; 
   if HospRate=. then HospRate=0 ; 
   if PropHosp=. then PropHosp=0 ; 

   Counties='Colorado';  Ages='0-5 yo';
run;
   proc print data= Colorado0_5_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=Colorado0_5_dates   out=Colorado0_5_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
      convert NumHosp=Hosp7dAv / transformout=(movave 7);
      convert HospRate=HospRates7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp14dAv / transformout=(movave 14);
run;
   PROC print data= Colorado0_5_MoveAv;
run;



***  Age group:  6-11 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County ^= 'INTERNATIONAL' ;   var Yrs6_11 ;   run;

   %Let agepopulation = 417859 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Colorado6_11; set COVID.CEDRS_view_fix ;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  (6 le  Age_at_Reported  < 12);
   keep ProfileID EventID ReportedDate Age_at_Reported County hospitalized;
run;
  PROC sort data=Colorado6_11  out= Colorado6_11_sort; by ReportedDate;
   proc print data= Colorado6_11_sort ;  ID ReportedDate ;  run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Colorado6_11_rate; set Colorado6_11_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then do; NumCases=0; NumHosp=0; end;
   NumCases+1; 
   if hospitalized=1 then NumHosp+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      HospRate= NumHosp / (&agepopulation/100000);
      PropHosp= (NumHosp / NumCases) * 100 ;
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County  hospitalized ;
run;
   proc print data= Colorado6_11_rate ;  ID ReportedDate ;  run;

** add ALL reported dates for populations with sparse data **;
Data Colorado6_11_dates; merge Timeline  Colorado6_11_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   if NumHosp=.  then NumHosp=0 ; 
   if HospRate=. then HospRate=0 ; 
   if PropHosp=. then PropHosp=0 ; 

   Counties='Colorado';  Ages='6-11 yo';
run;
   proc print data= Colorado6_11_dates ;  ID ReportedDate ;  run;


**  Calculate 7-day moving averages  **;
   PROC expand data=Colorado6_11_dates   out=Colorado6_11_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
      convert NumHosp=Hosp7dAv / transformout=(movave 7);
      convert HospRate=HospRates7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp14dAv / transformout=(movave 14);
run;
   PROC print data= Colorado6_11_MoveAv;
run;



***  Age group:  12-17 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County ^= 'INTERNATIONAL' ;   var Yrs12_17 ;   run;

   %Let agepopulation = 446886 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Colorado12_17; set COVID.CEDRS_view_fix ;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  (12 le  Age_at_Reported < 18);
   keep ProfileID EventID ReportedDate Age_at_Reported County hospitalized;
run;
  PROC sort data=Colorado12_17  out= Colorado12_17_sort; by ReportedDate;
/*   proc print data= Colorado12_17_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Colorado12_17_rate; set Colorado12_17_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then do; NumCases=0; NumHosp=0; end;
   NumCases+1; 
   if hospitalized=1 then NumHosp+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      HospRate= NumHosp / (&agepopulation/100000);
      PropHosp= (NumHosp / NumCases) * 100 ;
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County  hospitalized ;
run;
/*   proc print data= Colorado12_17_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Colorado12_17_dates; merge Timeline  Colorado12_17_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   if NumHosp=.  then NumHosp=0 ; 
   if HospRate=. then HospRate=0 ; 
   if PropHosp=. then PropHosp=0 ; 

   Counties='Colorado';  Ages='12-17 yo';
run;
/*   proc print data= Colorado12_17_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Colorado12_17_dates   out=Colorado12_17_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
      convert NumHosp=Hosp7dAv / transformout=(movave 7);
      convert HospRate=HospRates7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp14dAv / transformout=(movave 14);
run;
   PROC print data= Colorado12_17_MoveAv;
run;



***  Age group:  18-115 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County ^= 'INTERNATIONAL' ;   var Yrs18_121 ;   run;

   %Let agepopulation = 4503600 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Colorado18_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  (18 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County hospitalized;
run;
  PROC sort data=Colorado18_115  out= Colorado18_115_sort; by ReportedDate;
/*   proc print data= Colorado18_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Colorado18_115_rate; set Colorado18_115_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then do; NumCases=0; NumHosp=0; end;
   NumCases+1; 
   if hospitalized=1 then NumHosp+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      HospRate= NumHosp / (&agepopulation/100000);
      PropHosp= (NumHosp / NumCases) * 100 ;
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County  hospitalized ;
run;
/*   proc print data= Colorado18_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Colorado18_115_dates; merge Timeline  Colorado18_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   if NumHosp=.  then NumHosp=0 ; 
   if HospRate=. then HospRate=0 ; 
   if PropHosp=. then PropHosp=0 ; 

  Counties='Colorado';  Ages='18-115 yo';
run;
/*   proc print data= Colorado18_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Colorado18_115_dates   out=Colorado18_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
      convert NumHosp=Hosp7dAv / transformout=(movave 7);
      convert HospRate=HospRates7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp14dAv / transformout=(movave 14);
run;
   PROC print data= Colorado18_115_MoveAv;
run;



***  Age group:  ALL ages  ***;
***------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County ^= 'INTERNATIONAL' ;   var County_Population_Est ;   run;

   %Let agepopulation = 5763979 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Colorado0_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned ^= 'INTERNATIONAL' ;* AND  (0 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County hospitalized;
run;
  PROC sort data=Colorado0_115  out= Colorado0_115_sort; by ReportedDate;
/*   proc print data= Colorado0_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Colorado0_115_rate; set Colorado0_115_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then do; NumCases=0; NumHosp=0; end;
   NumCases+1; 
   if hospitalized=1 then NumHosp+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      HospRate= NumHosp / (&agepopulation/100000);
      PropHosp= (NumHosp / NumCases) * 100 ;
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County  hospitalized ;
run;
/*   proc print data= Colorado0_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Colorado0_115_dates; merge Timeline  Colorado0_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   if NumHosp=.  then NumHosp=0 ; 
   if HospRate=. then HospRate=0 ; 
   if PropHosp=. then PropHosp=0 ; 

   Counties='Colorado';  Ages='0-115 yo';
run;
/*   proc print data= Colorado0_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Colorado0_115_dates   out=Colorado0_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
      convert NumHosp=Hosp7dAv / transformout=(movave 7);
      convert HospRate=HospRates7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp7dAv / transformout=(movave 7);
      convert PropHosp=PropHosp14dAv / transformout=(movave 14);
run;
   PROC print data= Colorado0_115_MoveAv;
run;
