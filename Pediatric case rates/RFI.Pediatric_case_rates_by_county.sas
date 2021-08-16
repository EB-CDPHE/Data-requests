/**********************************************************************************************
PROGRAM:  RFI.Pediatric_case_rates_by_county.sas
AUTHOR:   Eric Bush
CREATED:  August 13, 2021
MODIFIED:	
PURPOSE:	 RFI on pediatric case rates (7 d avg) by age group for selected counties
INPUT:		COVID.CEDRS_fix   COVID.B6172_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

TITLE;
OPTIONS pageno=1;
/*________________________________________________________________________________________*
 | Programs to run prior to this code:
 *________________________________________________________________________________________*/

/*________________________________________________________________________________*
 | TABLE OF CONTENTS:
 | 1. Obtain county population data for specified age groups
 | 2. Create timeline of all dates for COVID epidemic (March 1, 2020 - present)
 *________________________________________________________________________________*/


***  Obtain county population data for specified age groups  ***;
***----------------------------------------------------------***;

** source:  https://demography.dola.colorado.gov/population/data/sya-county/   **;
** define age group intervals 0-5,  6-11,  12-17, and 18-121 for ALL counties
** Download csv, clean up file, and save Excel workbook (xlsx) as CntyPopAge.xlsx  **;

** Create libname with XLSX engine that points to XLSX file **;
libname mysheets xlsx 'C:\Users\eabush\Documents\CDPHE\Requests\data\Pediatric pop by county.xlsx' ;

** see contents of libref - one dataset for each tab of the spreadsheet **;
proc contents data=mysheets._all_ ; run;

** print tabs from spreadsheet **;
proc print data=mysheets.data; run;

/*DATA CntyPopAge; set mysheets.data;*/
/*   keep County Age Total;*/
/*run;*/

**  Sort by county and transpose pop data by age groups  **;
   proc sort data=mysheets.data(keep=County Age Total)  out=CntyPopAge; by County; 
   PROC transpose data= CntyPopAge  out=CountyPopbyAge;
      by County;
      id Age;
      var Total;
run;
/*   proc print data= CountyPopbyAge; run;*/


**  Define age pop variables  **;
DATA CountyPop_est ; 
   length County $ 11;
   set CountyPopbyAge(rename=(County=tmp_county)) ;

   County=upcase(tmp_county);
   format County $11.;
     Yrs0_5 = input(compress(_0_to_5,','), best12.) ;
    Yrs6_11 = input(compress(_6_to_11,','), best12.) ;
   Yrs12_17 = input(compress(_12_to_17,','), best12.) ;
  Yrs18_121 = input(compress(_18_to_121, ','), best12.) ;
   County_population_est = Yrs0_5 +  Yrs6_11  +  Yrs12_17  +  Yrs18_121;
   Label
        Yrs0_5    = 'Population for 0-5 year olds'
       Yrs6_11    = 'Population for 6-11 year olds'
      Yrs12_17    = 'Population for 12-17 year olds'
     Yrs18_121  = 'Population for 18-121 year olds' ;
   drop _NAME_  tmp_county  _0_to_5   _6_to_11   _12_to_17   _18_to_121   ;
run;
   proc print data= CountyPop_est; 
run;



*** Create timeline of all dates ***;
***------------------------------***;

DATA timeline;
   ReportedDate='01MAR20'd;
   output;
   do t = 1 to 530;
      ReportedDate+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop t ;
run;
/*proc print data= timeline;  run;*/

   

***------------------***;
***  COUNTIES = ALL  ***;
***  AGE GRPS = ALL  ***;
***------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum maxdec=0 ;  var County_Population_est ;  run;

   %Let agepopulation = 5763979 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data ALL0_121; set COVID.CEDRS_view_fix ;
   if (0 < Age_at_Reported < 121);
   keep ProfileID  EventID  ReportedDate  Age_at_Reported  County;
run;
  PROC sort data=ALL0_121  out= ALL0_121_sort; by ReportedDate;


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data ALL0_121_rate; set ALL0_121_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then NumCases=0;
   NumCases+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      Counties='ALL counties';  Ages='ALL ages';
      output;
   end;
* define population *;

* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County;
run;
/*   proc print data= ALL0_121_rate ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;

** Option 1 **;
DATA ALL0_121_moving ;  set ALL0_121_rate ;
   by ReportedDate;

* set last 7 values for cases and case rates *;
   NumCases6 = lag(NumCases);  CaseRate6 = lag(CaseRate);
   NumCases5 = lag2(NumCases);  CaseRate5 = lag2(CaseRate);
   NumCases4 = lag3(NumCases);  CaseRate4 = lag3(CaseRate);
   NumCases3 = lag4(NumCases);  CaseRate3 = lag4(CaseRate);
   NumCases2 = lag5(NumCases);  CaseRate2 = lag5(CaseRate);
   NumCases1 = lag6(NumCases);  CaseRate1 = lag6(CaseRate);

* calculate moving 7 day average for cases and case rates *;
   if _n_ ge 7 then DO;
      Cases_7davg = mean(NumCases, NumCases1, NumCases2, NumCases3, NumCases4, NumCases5, NumCases6);
      Rate_7davg  = mean(CaseRate, CaseRate1, CaseRate2, CaseRate3, CaseRate4, CaseRate5, CaseRate6);
   END;

* drop lag variables *;
   DROP NumCases1-NumCases6 ;
run;
   proc print data= ALL0_121_moving; 
   id ReportedDate; var NumCases  Cases_7davg  Rate_7davg ;
run;


** Option 2 **;
proc expand data=ALL0_121_rate   out=ALL0_121_MoveAv  method=none;
   id ReportedDate;
   convert NumCases=Mov7dAv / transformout=(movave 7);
run;
proc print data= ALL0_121_MoveAv; run;



***----------------------***;
***  COUNTIES = Boulder  ***;
***----------------------***;

***  Age group:  0-5 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BOULDER' ;   var Yrs0_5 ;   run;

   %Let agepopulation = 16721 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Boulder0_5; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BOULDER'  AND  (0 le  Age_at_Reported  < 6);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Boulder0_5  out= Boulder0_5_sort; by ReportedDate;
/*   proc print data= Boulder0_5_sort ;  ID ReportedDate ;  run;*/


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data Boulder0_5_rate; set Boulder0_5_sort;
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
/*   proc print data= Boulder0_5_rate ;  ID ReportedDate ;  run;*/


** add ALL reported dates for populations with sparse data **;
Data Boulder0_5_dates; merge Timeline  Boulder0_5_rate;
   by ReportedDate;

   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='BOULDER';  Ages='0-5 yo';
run;
/*   proc print data= Boulder0_5_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Boulder0_5_dates   out=Boulder0_5_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Boulder0_5_MoveAv;
run;



***  Age group:  6-11 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BOULDER' ;   var Yrs6_11 ;   run;

   %Let agepopulation = 20487 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Boulder6_11; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BOULDER'  AND  (6 le  Age_at_Reported  < 12);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Boulder6_11  out= Boulder6_11_sort; by ReportedDate;
/*   proc print data= Boulder6_11_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Boulder6_11_rate; set Boulder6_11_sort;
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
/*   proc print data= Boulder6_11_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Boulder6_11_dates; merge Timeline  Boulder6_11_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='BOULDER';  Ages='6-11 yo';
run;
/*   proc print data= Boulder6_11_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Boulder6_11_dates   out=Boulder6_11_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Boulder6_11_MoveAv;
run;



***  Age group:  12-17 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BOULDER' ;   var Yrs12_17 ;   run;

   %Let agepopulation = 24177 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Boulder12_17; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BOULDER'  AND  (12 le  Age_at_Reported < 18);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Boulder12_17  out= Boulder12_17_sort; by ReportedDate;
/*   proc print data= Boulder12_17_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Boulder12_17_rate; set Boulder12_17_sort;
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
/*   proc print data= Boulder12_17_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Boulder12_17_dates; merge Timeline  Boulder12_17_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='BOULDER';  Ages='12-17 yo';
run;
/*   proc print data= Boulder12_17_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Boulder12_17_dates   out=Boulder12_17_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Boulder12_17_MoveAv;
run;



***  Age group:  18-115 year olds  ***;
***-----------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BOULDER' ;   var Yrs18_121 ;   run;

   %Let agepopulation = 265779 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Boulder18_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BOULDER'  AND  (18 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Boulder18_115  out= Boulder18_115_sort; by ReportedDate;
/*   proc print data= Boulder18_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Boulder18_115_rate; set Boulder18_115_sort;
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
/*   proc print data= Boulder18_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Boulder18_115_dates; merge Timeline  Boulder18_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='BOULDER';  Ages='18-115 yo';
run;
/*   proc print data= Boulder18_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Boulder18_115_dates   out=Boulder18_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Boulder18_115_MoveAv;
run;



***  Age group:  ALL ages  ***;
***------------------------***;

** Set population for age group **;
   PROC means data= CountyPop_est n sum  maxdec=0 ;   where County = 'BOULDER' ;   var County_Population_Est ;   run;

   %Let agepopulation = 327164 ;      * <-- pull number from county population;


**  Create age specific dataset and sort by date  **;
 Data Boulder0_115; set COVID.CEDRS_view_fix ;
   if CountyAssigned = 'BOULDER' ;* AND  (0 le  Age_at_Reported < 116);
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
  PROC sort data=Boulder0_115  out= Boulder0_115_sort; by ReportedDate;
/*   proc print data= Boulder0_115_sort ;  ID ReportedDate ;  run;*/

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Boulder0_115_rate; set Boulder0_115_sort;
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
/*   proc print data= Boulder0_115_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Boulder0_115_dates; merge Timeline  Boulder0_115_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   Counties='BOULDER';  Ages='0-115 yo';
run;
/*   proc print data= Boulder0_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Boulder0_115_dates   out=Boulder0_115_MoveAv  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;
   PROC print data= Boulder0_115_MoveAv;
run;




