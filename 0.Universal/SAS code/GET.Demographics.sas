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
      a) 2020 Census data for Colorado - State and Counties 
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
   
   2. race-estimates-region.csv 
      a) STATE and Regional population estimates by Race/Ethnicity, Age, and Gender
      b) dowloaded from https://demography.dola.colorado.gov/assets/html/population.html 
      c) Population estimates by year (2010 - 2020) for Colorado State and Regions and Planning Regions
      d) View region map here:  https://coloradodemography.github.io/gis/colorado-regions/#understanding-colorado-regions
      e) 



 C. Colorado age population


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

   County_FIPS = substr(GEOCODE,3);
   label  County_FIPS = 'FIPS Code';
   Format County_FIPS $3.;

   County = upcase(tmp_County);
   DROP tmp_County  GEOCODE ;

run;

 ** Contents of dataset **;
  PROC contents data=CO2020pop_Cnty  varnum ; title1 'CO2020pop_Cnty'; run;

 ** View of dataset **;
   proc print data=CO2020pop_Cnty; run;
                                       



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
DATA CO2020est_Cnty;   
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
  PROC contents data=CO2020est_Cnty  varnum ; title1 'CO2020est_Cnty'; run;

 ** View of dataset **;
   proc print data=CO2020est_Cnty; run;




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
libname  B1Pop  xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data\demographics\Population 2020 Counties by Race and Ethnicity.xlsx' ; run;

   proc contents data= B1Pop.data  varnum ; run;


   proc format;
      value $RaceFmt
      Hispanic_all_races = 'Hispanic (All Races)'
      White_Non_Hispanic = 'White (Non-Hispanic)'
      Black_Non_Hispanic = 'Black (Non-Hispanic)'
      Native_American_Non_Hispanic = 'Native American/Alaskan Native (Non-Hispanic)'
      Asian_Non_Hispanic = 'Asian/Pacific Islander (Non-Hispanic)'
      Multiple_Races_Non_Hispanic = 'Multiple Races (Non-Hispanic)'
      Other_Race_Non_Hispanic = 'Other Race (Non-Hispanic)' ;
run;

/*---------------------------------------------------------------------------------------------------------------*
 | Structure of this dataset is 'wide', i.e. column for each race.
 | This dataset needs to be transposed, i.e. variable for Race_Ethnicity and variable for Population (counts)
 *---------------------------------------------------------------------------------------------------------------*/

/*____________________________________________________________________________________________________________________________________*/


*** FOR STATE-level population counts ***;
***-----------------------------------***;

** Create SAS dataset from spreadsheet **;
DATA CO2020pop_Race;   
   set B1Pop.data(Rename=(
      White_Alone = White_Non_Hispanic
      Black_African_American_Alone = Black_Non_Hispanic
      American_Indian___Alaska_Native = Native_American_Non_Hispanic
      Asian_Pacific_Islander_Alone = Asian_Non_Hispanic
      Two_or_More_Races_Total = Multiple_Races_Non_Hispanic
      Some_Other_Race_Alone = Other_Race_Non_Hispanic
      Hispanic_Latino_Origin__of_any_r = Hispanic_all_races    ));

   where GEOCODE = '08' ;              * For STATE-level use ='08' ;

   array RaceGrps{7} White_Non_Hispanic   Black_Non_Hispanic  Native_American_Non_Hispanic  Asian_Non_Hispanic  
                     Multiple_Races_Non_Hispanic  Other_Race_Non_Hispanic  Hispanic_all_races ;

   do r = 1 to 7;
      Race_Ethnicity = vname( RaceGrps{r} );
      Population = RaceGrps{r};

      output;
   end;

   Rename GEOCODE = FIPS;
   label  GEOCODE = 'FIPS Code';

   DROP  R   White_Non_Hispanic   Black_Non_Hispanic  Native_American_Non_Hispanic  Asian_Non_Hispanic  
             Multiple_Races_Non_Hispanic  Other_Race_Non_Hispanic  Hispanic_all_races;
run;

 ** Contents of dataset **;
  PROC contents data=CO2020pop_Race  varnum ; title1 'CO2020pop_Race'; run;

 ** View of dataset **;
   proc print data=CO2020pop_Race; 
      format Race_Ethnicity $RaceFmt. ;
run;


/*____________________________________________________________________________________________________________________________________*/


*** FOR COUNTY-level population counts ***;
***-----------------------------------***;

** Create SAS dataset from spreadsheet **;
DATA Cnty_Race_TEMP;   
   length County_FIPS $ 3;
   set B1Pop.data(rename=(County=tmp_County));

   where GEOCODE ^= '08' ;              * For COUNTY-level use ='08' ;

   County_FIPS = substr(GEOCODE,3);
   label  County_FIPS = 'FIPS Code';
   Format County_FIPS $3.;

   County = upcase(tmp_County);

   DROP  GEOCODE  tmp_County ;
run;
 ** Contents of dataset **;
/*  PROC contents data=Cnty_Race_TEMP  varnum ; title1 'Cnty_Race_TEMP'; run;*/
 ** View of dataset **;
/*   proc print data=Cnty_Race_TEMP; run;*/


** Create SAS dataset from spreadsheet **;
DATA CO2020pop_Cnty_Race;   
   set Cnty_Race_TEMP(Rename=(
      White_Alone = White_Non_Hispanic
      Black_African_American_Alone = Black_Non_Hispanic
      American_Indian___Alaska_Native = Native_American_Non_Hispanic
      Asian_Pacific_Islander_Alone = Asian_Non_Hispanic
      Two_or_More_Races_Total = Multiple_Races_Non_Hispanic
      Some_Other_Race_Alone = Other_Race_Non_Hispanic
      Hispanic_Latino_Origin__of_any_r = Hispanic_all_races    ));


   array RaceGrps{7} White_Non_Hispanic   Black_Non_Hispanic  Native_American_Non_Hispanic  Asian_Non_Hispanic  
                     Multiple_Races_Non_Hispanic  Other_Race_Non_Hispanic  Hispanic_all_races ;

   do r = 1 to 7;
      Race_Ethnicity = vname( RaceGrps{r} );
      Population = RaceGrps{r};
      output;
   end;

   DROP  R   White_Non_Hispanic   Black_Non_Hispanic  Native_American_Non_Hispanic  Asian_Non_Hispanic  
             Multiple_Races_Non_Hispanic  Other_Race_Non_Hispanic  Hispanic_all_races  ;
run;

 ** Contents of dataset **;
  PROC contents data=CO2020pop_Cnty_Race  varnum ; title1 'CO2020pop_Cnty_Race'; run;

 ** View of dataset **;
   proc print data=CO2020pop_Cnty_Race; 
      format Race_Ethnicity $RaceFmt. ;
run;






*** Code to access B.2  ***;
***---------------------***;

/*_______________________________________________________________________________________________________________________________*
 | For 2020 county level population data BY RACE and ETHNICITY:
 |-------------------------------------------------------------------------------------------------------------------------------*
 | SOURCE:  https://coloradodemography.github.io/WebsiteGrid/assets/html/population.html  
 |
 | STEPS:
 |  1) In section for County Spreadsheets, select "County Population Estimates by Race/Ethnicity, Age and Sex, 2010 to 2020
 |  2) download csv. Default filename is "race-estimates-county.csv" 
 |  3) open CSV file, delete ID column, Rename Tab to DATA --> then save as Excel file
 |  4) Save as Excel file 
/*_______________________________________________________________________________________________________________________________*/

** Create libname with XLSX engine that points to XLSX file **;
libname B2Pop xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data\demographics\race-estimates-county.xlsx' ;

** see contents of libref - one dataset for each tab of the spreadsheet **;
   PROC contents data=B2Pop.data  varnum ; title1; run;


** Create SAS dataset from spreadsheet **;
DATA CO2020est_Cnty_Race_Age_TEMP;  length Race_Ethnicity $ 22 ;  set B2Pop.DATA;
/*   where year=2020;*/
   rename sex=Gender;
   rename count=Population;
   format County_Fips z3. ;

* create single Race - Ethnicity variable *;
   if Ethnicity = 'Hispanic Origin' then Race_Ethnicity='Hispanic Origin';
   else Race_Ethnicity=Race;

run;

   PROC contents data=CO2020est_Cnty_Race_Age_TEMP  varnum ; title1 'CO2020est_Cnty_Race_Age_TEMP'; run;


*** Add county name to county FIPS code ***;
***-------------------------------------***;

/*-------------------------------------------------------*
 | The SDO data uses county FIPS to identify counties. 
 | COPHS data uses upcase county names.
 | Use CountyCodes spreadsheet to link FIPS and names.
 | SOURCE:
 | https://www.census.gov/geographies/reference-files/2020/demo/popest/2020-fips.html
 | Select "2020 State, County, ... FIPS Codes"
 *-------------------------------------------------------*/

** Create libname with XLSX engine that points to XLSX file **;
libname mycodes xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\25.Hosp Admissions by Race\Input data\countycodes.xlsx' ;
title;

** see contents of libref - one dataset for each tab of the spreadsheet **;
   proc contents data= mycodes.Sheet1  varnum ; run;

** Create SAS dataset from spreadsheet **;
DATA CountyCodes;  
   Set mycodes.Sheet1(Rename= 
                        (County_FIPS = tmp_County_FIPS
                         County_Name = tmp_County_Name) );

   County_FIPS = input(tmp_County_FIPS, best3.);
   length County_Name $ 20;
   County_Name = upcase( trim(tranwrd(tmp_County_Name, 'County','') ) )  ;
   DROP tmp_:  ;
   format County_Fips z3.  County_Name $20.;
run;

 ** Contents of dataset **;
  PROC contents data=CountyCodes  varnum ; title1 'CountyCodes'; run;

 ** View of dataset **;
   proc print data= CountyCodes; id County_FIPS;  run;



** Add CountyCodes to County Population data **;
   proc sort data=CO2020est_Cnty_Race_Age_TEMP
               out=Pop_sort ;
      by County_FIPS ;
   proc sort data=CountyCodes
               out=Code_sort ;
      by County_FIPS ;
Data CO2020est_Cnty_Race_Age_Sex;
   merge  Code_sort  Pop_sort;
   by County_FIPS ;

   DROP Race Ethnicity;
run;

** Check link between County FIPS code and County Name **;
   PROC freq data= CO2020est_Cnty_Race_Age;
      tables County_FIPS * County_Name / list ;
run;

 ** Contents of dataset **;
   PROC contents data=CO2020est_Cnty_Race_Age_Sex  varnum ; title1 'CO2020est_Cnty_Race_Age_Sex'; run;

 ** View of dataset **;
   PROC print data= CO2020est_Cnty_Race_Age_Sex; id County_FIPS;  run;


 ** Summary of dataset - Race/Ethnicity **;
   PROC means data = CO2020est_Cnty_Race_Age_Sex  sum  maxdec=0;
      var Population;
      class Race_Ethnicity;
/*      format Race_Ethnicity $RaceFmt. ;*/
run;

 ** Summary of dataset - County **;
   PROC means data = CO2020est_Cnty_Race_Age_Sex  sum  maxdec=0;
      var Population;
      class County_Name;
run;
