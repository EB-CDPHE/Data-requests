/**********************************************************************************************
PROGRAM:  CHART.Pediatric_case_rates_by_county.sas
AUTHOR:   Eric Bush
CREATED:  August 13, 2021
MODIFIED:	
PURPOSE:	 To export data on pediatric case rates (7 d avg) by age group for selected counties
            in order to chart in excel or Tableau
INPUT:		COVID.CEDRS_fix   COVID.County_Population
OUTPUT:		
***********************************************************************************************/


/*----------------------------------------------------------------------------------*
 | The county level population data is created via Access.Populations.sas
 | This is only useful when using entire county population, not age-specific pop
 *----------------------------------------------------------------------------------*/

** County Population data **;
   PROC contents data=COVID.County_Population; run;

/*   PROC print data= COVID.County_Population; id county; run;*/

   PROC means data= COVID.County_Population sum  maxdec=0;
      var population;
      class county;
run;


/*_________________________________________________________________________________________*
 | For 2019 county level population data BY AGE GROUPS:
 |-----------------------------------------------------------------------------------------*
 | SOURCE:  https://demography.dola.colorado.gov/population/data/sya-county/  
 | STEPS:
 |  1) define age group intervals (e.g. 0-5,  6-11,  12-17, and 18-121) for ALL counties
 |  2) download csv, clean up file, and save Excel workbook (xlsx) as CntyPopAge.xlsx 
 *-----------------------------------------------------------------------------------------*/

** Create libname with XLSX engine that points to XLSX file **;
libname mysheets xlsx 'C:\Users\eabush\Documents\CDPHE\Requests\data\Pediatric pop by county.xlsx' ;

** see contents of libref - one dataset for each tab of the spreadsheet **;
proc contents data=mysheets._all_ ; title1; run;

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
   drop _LABEL_  _NAME_  tmp_county  _0_to_5   _6_to_11   _12_to_17   _18_to_121   ;
run;
   PROC print data= CountyPop_est; run;


*** Make local copies of source data ***;
***----------------------------------***;

**  local copy of COVID.County_Population  **;
/*Data County_Pop; length County $13; set COVID.County_Population;*/
/*   keep County Population;*/
/*run;*/

**  local copy of COVID.CEDRS_view_fix  **;
DATA CEDRS_view_fix;  set COVID.CEDRS_view_fix;
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;



                                                  /*------------------*
                                                   | CaseRates Macro  |
*---------------------------------------------------------------------*
| Create macro to check calculate case rates by age group             |
| Defines macro variable:                                             |
|     &COcnty  -->  county name                                       |
|     &AgeGrp  -->  age group variable                                |
|     &AgeLB   -->  lower bound of age range                          |
|     &AgeUB   -->  upper bound of age range                          |
|                                                                     |
| What this macro does:                                               |
|  a) Create macro variable of population data for county and age group |
|  b) Create age specific dataset and sort by date |
|  c) Reduce dataset from patient level to date level (obs=reported date) |
|     - count cases per reported date
|     - calculate case rate
|     - drop patient level variables
|  d) add ALL reported dates for populations with sparse data |
|     - backfill missing caserate data with 0's |
|     - add vars to describe population                                |
|  f) Calculate 7-day moving averages |
|  g) delete temporary datasets created by macro that are not needed
|  h) Export data to Excel file (XLS) to be used in Tableau 
*---------------------------------------------------------------------*/



%Macro CaseRates(COcnty, AgeGrp, AgeLB, AgeUB);
DATA CEDRS_&COcnty;  set CEDRS_view_fix;
   where County = "&COcnty";   
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;

** Create macro variable of population data for county and age group **;
data _null_; set CountyPop_est; where County = "&COcnty" ;
   call symputx("agepopulation", &AgeGrp);    * <-- put number from county population into macro variable;
run;

**  Create age specific dataset and sort by date  **;
 Data &COcnty; set CEDRS_&COcnty;
    if &AgeLB le  Age_at_Reported  < &AgeUB;
run;
   PROC sort data= &COcnty  
              out= &COcnty._sort; 
      by ReportedDate;
run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data &COcnty._rate; set &COcnty._sort;
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

** add ALL reported dates for populations with sparse data **;
Data &COcnty._dates; length Ages $ 9;  merge Timeline  &COcnty._rate;
   by ReportedDate;

* backfill missing with 0 *; 
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 

*add vars to describe population *;
   Counties="&COcnty";  
   Ages="&AgeGrp";  format Ages $9.;

run;

**  Calculate 7-day moving averages  **;
   PROC expand data=&COcnty._dates   out=&COcnty._&AgeGrp  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;

* delete temp datasets not needed *;
proc datasets library=work NOlist ;
   delete &COcnty   &COcnty._rate   &COcnty._sort   &COcnty._dates  ;
run;


* Export data to Excel file (XLS) to be used in Tableau *;
PROC EXPORT DATA= &COcnty._&AgeGrp 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\Pediatric case rates\County data\Case_rates_&COcnty._&AgeGrp.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="data"; 
RUN;

%mend;


%CaseRates(ADAMS, Yrs0_5, 0, 6)  
%CaseRates(ADAMS, Yrs6_11, 6, 12)  
%CaseRates(ADAMS, Yrs12_17, 12, 18)  
%CaseRates(ADAMS, Yrs18_121, 18, 116)


%CaseRates(BACA, Yrs0_5, 0, 6)  
%CaseRates(BACA, Yrs6_11, 6, 12)  
%CaseRates(BACA, Yrs12_17, 12, 18)  
%CaseRates(BACA, Yrs18_121, 18, 116)


%CaseRates(ALAMOSA)
%CaseRates(ARAPAHOE)
%CaseRates(ARCHULETA)

Data Baca_combine; 
   set Baca_yrs0_5   Baca_yrs6_11   Baca_yrs12_17   Baca_yrs18_121  ;
   proc sort data=Baca_combine
               out=Baca_cases;
      by ReportedDate;
run;

proc print data=Baca_cases ;
   where '01JUL20'd le ReportedDate le '31JUL20'd;
run;

PROC EXPORT DATA= Adams_combine 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\Pediatric case rates\County data\Adams_combine.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="data"; 
RUN;





