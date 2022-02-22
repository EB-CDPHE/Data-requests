/**********************************************************************************************
PROGRAM:  RFI.Hosp_rates_Race.sas
AUTHOR:   Eric Bush
CREATED:  February 21, 2022
MODIFIED:	
PURPOSE:	  
INPUT:	 COVID.COPHS_fix     	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;


*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA COPHS_fix;  set COVID.COPHS_fix;
   where '01MAR2020'd  le  Hosp_Admission le  '01DEC2022'd; ;
   Keep Facility_Name MR_Number First_Name Last_Name Gender Race Ethnicity County_of_Residence
        Date_Added COPHS_Breakthrough COVID19ICD10 Hosp_Admission ICU_Admission DOB Positive_Test ;
run;

   PROC contents data=COPHS_fix  varnum; title1 'COPHS_fix'; run;



*** Number of cases by Ethnicity and Race ***;
***---------------------------------------***;
   PROC means data=COPHS_fix  n  maxdec=0;
      var Hosp_Admission ;
      class Ethnicity;
      title1 'Number of Hospitalizations:  Hispanics';
run;
   PROC means data=COPHS_fix  n  maxdec=0;
      where Ethnicity ^= 'Hispanic or Latino';
      var Hosp_Admission ;
      title1 'Number of Hospitalizations:  Non-Hispanics';
      class Race;
run;

   PROC freq data= COPHS_fix ;
      tables Hosp_Admission * Ethnicity /norow nocol nopercent  ;
      format Hosp_Admission monyy. ;
      title1 'Number of Hospitalizations:  Hispanics';
      title2 'by Month';
run;


***  Access population data  ***;
***--------------------------***;

***  Obtain county population data for Race and Ethnicity  ***;
***--------------------------------------------------------***;

/*_________________________________________________________________________________________*
 | For 2020 county level population data BY RACE and ETHNICITY:
 |-----------------------------------------------------------------------------------------------------------------*
 | SOURCE:  https://coloradodemography.github.io/WebsiteGrid/assets/html/population.html  
 | STEPS:
 |  1) In section for County Spreadsheets, select "County Population Estimates by Race/Ethlnicity, Age and Sex
 |  2) download csv, filter rows to Year=2020, and save as race-estimates-county-2020.csv 
 |  3) edit CSV file by formatting population count column as number with no decimals; delete ID column
 |  4) Save as County_Age_Gender_Race_2020pop.XLSX file in INPUT folder
 *-----------------------------------------------------------------------------------------------------------------*/

** Create libname with XLSX engine that points to XLSX file **;
libname mysheets xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\25.Hosp Admissions by Race\Input data\County_Age_Gender_Race_2020pop.xlsx' ;


** see contents of libref - one dataset for each tab of the spreadsheet **;
   PROC contents data=mysheets._all_  varnum ; title1; run;

** print tabs from spreadsheet **;
   proc print data=mysheets.DATA; run;

DATA County_Race; set mysheets.DATA;
   format County_FIPS z3.0 ;
   rename sex=Gender;
   rename count=Population;
run;

   PROC contents data=County_Race  varnum ; title1 'County_Race'; run;

** Calculate 2020 Colorado Population count by Race and Ethnicity **;
   PROC means data=County_Race  sum  maxdec=0;
      where Ethnicity = 'Hispanic Origin';
      var Population;
      class Ethnicity ;
run;

   PROC means data=County_Race  sum  maxdec=0;
      where Ethnicity ^= 'Hispanic Origin';
      var Population;
      class Race ;
run;


** Copy County population data by Race, Age, Gender to dashboard directory **;
DATA DASH.County_Race; set County_Race;
run;


