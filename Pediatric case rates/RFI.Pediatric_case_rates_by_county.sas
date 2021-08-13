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

/*________________________________________________________________________________*
 | TABLE OF CONTENTS:
 | 1. Obtain county population data for specified age groups
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

   proc print data= CountyPop_est; run;
