/**********************************************************************************************
PROGRAM:  GET.CO_Population_Race.sas
AUTHOR:   Eric Bush
CREATED:  February 21, 2022
MODIFIED:	
PURPOSE:	 Obtain Colorado population data for 2020 by County, Age, Race, and Ethnicity 
INPUT:	      	  
OUTPUT:	 DASH.County_Population	
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;


***  Obtain county population data for Race and Ethnicity  ***;
***--------------------------------------------------------***;

/*____________________________________________________________________________________________________________________________*
 | For 2020 county level population data BY RACE and ETHNICITY:
 |----------------------------------------------------------------------------------------------------------------------------*
 | SOURCE:  https://coloradodemography.github.io/WebsiteGrid/assets/html/population.html  
 |
 | STEPS:
 |  1) In section for County Spreadsheets, select "County Population Estimates by Race/Ethnicity, Age and Sex, 2010 to 2020
 |  2) download csv. Default filename is "race-estimates-county.csv" 
 |  3) open CSV file, delete ID column, Rename Tab to DATA --> then save as Excel file
 |  4) Save as Excel file file in INPUT folder
 *----------------------------------------------------------------------------------------------------------------------------*/

** Create libname with XLSX engine that points to XLSX file **;
libname mysheets xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\25.Hosp Admissions by Race\Input data\race-estimates-county.xlsx' ;


** see contents of libref - one dataset for each tab of the spreadsheet **;
   PROC contents data=mysheets._all_  varnum ; title1; run;

** print tabs from spreadsheet **;
   proc print data=mysheets.DATA; run;

** Create SAS dataset from spreadsheet **;
DATA County_Race_POP2020; length Race_Ethnicity $ 22 ;  set mysheets.DATA;
   where year=2020;
   rename sex=Gender;
   rename count=Population;

* create single Race - Ethnicity variable *;
   if Ethnicity = 'Hispanic Origin' then Race_Ethnicity='Hispanic Origin';
   else Race_Ethnicity=Race;
run;

   PROC contents data=County_Race_POP2020  varnum ; title1 'County_Race_POP2020'; run;

** Calculate 2020 Colorado Population count by Race and Ethnicity **;
   PROC means data=County_Race_POP2020  sum  maxdec=0;
      where Ethnicity = 'Hispanic Origin';
      var Population;
      class Ethnicity ;

run;

   PROC means data=County_Race_POP2020  sum  maxdec=0;
      where Ethnicity ^= 'Hispanic Origin';
      var Population;
      class Race ;
run;

   PROC means data=County_Race_POP2020  sum  maxdec=0;
      var Population;
      class Race_Ethnicity ;
run;

   PROC freq data= County_Race_POP2020;  
      tables Race_Ethnicity * Ethnicity * Race / list ; 
run;


*** Add county name to county FIPS code ***;
***-------------------------------------***;

   proc contents data= CntyCodes  varnum ; run;

   PROC print data= CntyCodes; id County_Code; run;

DATA CountyCodes;  Set CntyCodes;
   Rename County_Code = County_FIPS;
run;
   proc contents data= CountyCodes varnum ; run;


   proc sort data=County_Race_POP2020
               out=Pop_sort ;
      by County_FIPS ;
   proc sort data=CountyCodes
               out=Code_sort ;
      by County_FIPS ;
Data County_Population;
   merge Pop_sort Code_sort ;
   by County_FIPS ;
run;

   PROC contents data=County_Population  varnum ; title1 'County_Population'; run;


** Check link between County FIPS code and County Name **;
   PROC freq data= County_Population ;
      tables County_FIPS * County_Name / list ;
run;

** Population count for Race_Ethnicity groups **;
   PROC means data = County_Population  sum  maxdec=0;
      var Population;
      class Race_Ethnicity;
run;


*** Copy County population data by Race, Age, Gender to dashboard directory ***;
***-------------------------------------------------------------------------***;

libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;

DATA DASH.County_Population; set County_Population;
run;








