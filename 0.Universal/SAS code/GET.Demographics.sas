/**********************************************************************************************
PROGRAM:  GET.Demogrpahics.sas
AUTHOR:   Eric Bush
CREATED:  March 26, 2022
MODIFIED:	
PURPOSE:	 One code for accessing various demographic sources for Colorado
INPUT:	 COVID.COPHS_fix     	  
OUTPUT:	 DASH.COPHS_fix	
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;


/*
 A. Colorado County populations
   1. Population 2020 Counties.xlsx
      a) 2020 Census data for Colorado State and Counties 
      b) State and County FIPS stored in Column A as "GEOCODE"
      c) For State level population, GEOCODE = '08';
         For County level population GEOCODE ^= '08';

   2. CountyRankings.xlsx 
      a) Population estimates by year (2010 - 2020) for Colorado State and Counties 
      b) County FIPS and county name (stored as "Area")
      c) For State level population, County_FIPS = '000';
         For County level population County_FIPS ^= '000';
      d) Use for population estimates in most recent year or years between decennial Census


 B. Colorado Race-Ethnicity population
   1. Population by Race and Ethnicity 2020 Counties.xlsx
      a) 2020 Census data for Colorado State and Counties 
      b) State and County FIPS stored in Column A as "GEOCODE"
      c) For State level population, GEOCODE = '08';
         For County level population GEOCODE ^= '08';
      d) Column C has no header. There are two lines per GEOCODE, Count and Percentage.
      e) Race and Ethnicity groups are:
         1) White alone (Non-Hispanic/Latino)
         2) Black/African American Alone (Non-Hispanic/Latino)
         3) American Indian & Alaska Native Alone (Non-Hispanic/Latino)
         4) Asian/Pacific Islander Alone (Non-Hispanic/Latino)
         5) Some Other Race Alone (Non-Hispanic/Latino)
         6) Two or More Races Total (Non-Hispanic/Latino)
         7) Hispanic/Latino Origin (of any race)
          


   2. race-estimates-region.csv for STATE and Regional population estimates by Race/Ethnicity, Age, and Gender
      a) dowloaded from https://demography.dola.colorado.gov/assets/html/population.html
      b) Population estimates by year (2010 - 2020) for Colorado State and Regions and Planning Regions
      c) View region map here:  https://coloradodemography.github.io/gis/colorado-regions/#understanding-colorado-regions

 C. Colorado age population
   1. XXX for 1 year interval




   2. race-estimates-county.csv for COUNTY population estimates by Race/Ethnicity, Age, and Gender


*/



*** Code to access A.1  ***;
***---------------------***;

/*____________________________________________________________________________________________________________________________________*
 | 2020 Census data for COLORADO BY COUNTY:
 |------------------------------------------------------------------------------------------------------------------------------------*
 | SOURCE:  https://demography.dola.colorado.gov/assets/html/acs.html  
 |
 | STEPS:
 |  1) In section for Census Resources, select "Decennial Census Data, Maps, and Spreadsheets"
 |  2) select "Census Redistricting Data, 2020:"
 |  3) Under Population 2020, select "Population 2020 Counties"
 |  4) download Excel spreadsheet. Default filename is "Population 2020 Counties.xlsx" 
 |  5) open file, delete rows 1-4, rename (new) C2) from 2020 to "Population", delete blank row between "Colorado" and "Counties"
       delete final 4 rows that come after data, rename Tab to DATA 
 |  6) Save as Excel file file in Universal Data folder, /Demographic subfolder
/*____________________________________________________________________________________________________________________________________*/


** Create libname with XLSX engine that points to XLSX file **;
libname  A1Pop  xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data\demographics\Population 2020 Counties.xlsx' ; run;

   proc contents data= A1Pop.data  varnum ; run;

/*____________________________________________________________________________________________________________________________________*/


*** FOR STATE-level population counts ***;
***-----------------------------------***;

** Create SAS dataset from spreadsheet **;
DATA CO2020pop;   
   set A1Pop.data;

   where GEOCODE = '08' ;              * For STATE-level use ='08' ;

   Rename GEOCODE = FIPS;
   label  GEOCODE = 'FIPS Code';
run;

 ** Contents of dataset **;
  PROC contents data=CO2020pop  varnum ; title1 'CO2020pop'; run;

 ** View of dataset **;
   proc print data=CO2020pop; run;


/*____________________________________________________________________________________________*/


*** FOR COUNTY-level population counts ***;
***-----------------------------------***;

** Create SAS dataset from spreadsheet **;
DATA CO2020pop_Cnty;   
   length County_FIPS $ 3;
   set A1Pop.data(rename=(County=tmp_County));

   where GEOCODE ^= '08' ;              * For COUNTY-level use ^='08' ;

   County_FIPS = substr(GEOCODE,3,5);
   label  County_FIPS = 'FIPS Code';
   Format County_FIPS $3.;

   County = upcase(tmp_County);
   DROP tmp_County  GEOCODE ;

run;

 ** Contents of dataset **;
  PROC contents data=CO2020pop  varnum ; title1 'CO2020pop'; run;

 ** View of dataset **;
   proc print data=CO2020pop; run;
                                       



*** Code to access A.2  ***;
***---------------------***;

/*_______________________________________________________________________________________________________________________________*
 | Yearly population estimates for COLORAOD and BY COUNTY:
 |-------------------------------------------------------------------------------------------------------------------------------*
 | SOURCE:  https://demography.dola.colorado.gov/assets/html/county.html  
 |
 | STEPS:
 |  1) In section for County Spreadsheets, select "County Population Estimates by Race/Ethnicity, Age and Sex, 2010 to 2020
 |  2) download Excel spreadsheet. Default filename is "CountyRankings.xlsx" 
 |  3) open file, delete row 1, delete final 3 rows, rename Tab to DATA 
 |  4) Save as Excel file file in Universal Data folder
/*_______________________________________________________________________________________________________________________________*/

** Create libname with XLSX engine that points to XLSX file **;
libname A2Pop xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data\demographics\CountyRankings.xlsx' ; run;

   proc contents data= mydemo.data  varnum ; run;

** Create SAS dataset from spreadsheet **;
DATA CO2020est;   
   set A2Pop.data;

   where County_FIPS ^= '000' ;          * For STATE-level use ='000' ;
                                         * For COUNTY-level use ^='000' ;

   length County_Name $ 20;
   County_Name = trim(tranwrd(Area, 'COUNTY','') ) ;

   Rename July_2020 = Population;
   label  July_2020 = '2020 Population';

   Rename _2020_rank = County_Rank;
   label  _2020_rank = 'County Rank';

   KEEP County_FIPS  County_Name  July_2020  _2020_rank ; 
run;

 ** Contents of dataset **;
  PROC contents data=CO2020est  varnum ; title1 'CO2020est'; run;

 ** View of dataset **;
   proc print data=CO2020est; run;





*** Code to access B.1  ***;
***---------------------***;

/*____________________________________________________________________________________________________________________________________*
 | 2020 Census data for COLORADO BY COUNTY and RACE/ETHNICITY:
 |------------------------------------------------------------------------------------------------------------------------------------*
 | SOURCE:  https://demography.dola.colorado.gov/assets/html/acs.html  
 |
 | STEPS:
 |  1) In section for Census Resources, select "Decennial Census Data, Maps, and Spreadsheets"
 |  2) select "Census Redistricting Data, 2020:"
 |  3) Under Population 2020, select "Population by Race and Ethnicity 2020 Counties"
 |  4) download Excel spreadsheet. Default filename is "Population by Race and Ethnicity 2020 Counties.xlsx" 
 |  5) open file, delete rows 1-5, 
 |     Need to get rid of rows where Col C = "Percentage". Could manually delete rows but I filtered out these rows and 
 |     copied result to new tab. Label new tab "DATA". Delete Col C (all values are "count").
 |  6) Save as Excel file file in Universal Data folder, /Demographic subfolder with new name:
 |     Population 2020 Counties by Race and Ethnicity.xlsx
/*____________________________________________________________________________________________________________________________________*/


** Create libname with XLSX engine that points to XLSX file **;
libname  B1Pop  xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data\demographics\Population 2020 Counties.xlsx' ; run;

   proc contents data= A1Pop.data  varnum ; run;

/*____________________________________________________________________________________________________________________________________*/


*** FOR STATE-level population counts ***;
***-----------------------------------***;

** Create SAS dataset from spreadsheet **;
DATA CO2020pop;   
   set A1Pop.data;

   where GEOCODE = '08' ;              * For STATE-level use ='08' ;

   Rename GEOCODE = FIPS;
   label  GEOCODE = 'FIPS Code';
run;

 ** Contents of dataset **;
  PROC contents data=CO2020pop  varnum ; title1 'CO2020pop'; run;

 ** View of dataset **;
   proc print data=CO2020pop; run;
