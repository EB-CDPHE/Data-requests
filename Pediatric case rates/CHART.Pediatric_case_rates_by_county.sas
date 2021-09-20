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

/*________________________________________________________________________________*
 | TABLE OF CONTENTS:
 | 1. Obtain county population data for specified age groups
 | 2. Make local copy of source data
 | x. Create timeline of all dates for COVID epidemic (March 1, 2020 - present)
 *________________________________________________________________________________*/


*** Obtain county population data for specified age groups ***;
***--------------------------------------------------------***;

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
   PROC contents data=mysheets._all_ ; title1; run;

** print tabs from spreadsheet **;
   proc print data=mysheets.data; run;

**  Sort by county and transpose pop data by age groups  **;
   proc sort data=mysheets.data(keep=County Age Total)  out=CntyPopAge; by County; 
   PROC transpose data= CntyPopAge  out=CountyPopbyAge;
      by County;
      id Age;
      var Total;
run;
/*   proc print data= CountyPopbyAge; run;*/

**  Define age population variables  **;
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


*** Make local copy of source data ***;
***--------------------------------***;

**  local copy of COVID.CEDRS_view_fix  **;
DATA CEDRS_view_fix;  set COVID.CEDRS_view_fix;
   keep ProfileID EventID ReportedDate Age_at_Reported County;
run;
proc contents data=CEDRS_view_fix varnum ; title1 'CEDRS_view_fix'; run;


***  Submit %AgeGrpRates macro  ***;
***-----------------------------***;

** Run macro to Calculate age-specific case rates for a county **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\macro.AgeGrpRates.sas' ;

/*______________________________________________________________*
| NOTE:
| This macro will be called below inside the %CntyRates macro
| Final output will be dataset for County and AgeGroup 
| Dataset name is &COcnty._&AgeGrp  e.g. Larimer_Yrs0_5
*_______________________________________________________________*/


***  Define %CntyRates macro  ***;
***---------------------------***;

                                                         /*------------------*
                                                          | CntyRates Macro  |
*----------------------------------------------------------------------------*
| PURPOSE: Combines age-specific case rates for a county into single dataset |
|                                                                            |
| Defines macro variable:                                                    |
|     &CountyName  -->  county name                                          |
|                                                                            |
| What this macro does:                                                      |
|  a) Add underscore to two part county names for use in DATA step statements|
|  b) Create county level dataset                                            |
|  c) Run %AgeGrpRates macro to create 4 age-specific county level case rates|
|     - Yrs0_5                                                               |
|     - Yrs6_11                                                              |
|     - Yrs12_17                                                             |
|     - Yrs18_121                                                            |
|  d) Combine the four age group datasets into one county level dataset      |
|  e) Delete age-specific datasets                                           |
*----------------------------------------------------------------------------*/



%macro CntyRates(CountyName);

   * Add underscore to two part county names for use in DATA step statements *;
   data _null_;  set CountyPop_est; 
      where County = "&CountyName" ;

      IF County in ("CLEAR CREEK", "EL PASO", "KIT CARSON", "LA PLATA", "LAS ANIMAS", "RIO BLANCO", "RIO GRANDE", "SAN JUAN", "SAN MIGUEL") 
      THEN DO;
         Cnty1= scan("&CountyName",1,' ');   
         Cnty2= scan("&CountyName",2,' ');   
         Cnty_Name= CATS(Cnty1, '_', Cnty2);
      END;
      ELSE  Cnty_Name= "&CountyName" ;
   
      call symputx("County_Name", Cnty_Name);    
   run;


   * Create county level dataset *;
   DATA CEDRS_&County_Name;  set CEDRS_view_fix;
     where County = "&CountyName";   
     keep ProfileID EventID ReportedDate Age_at_Reported County;
   run;

   * Run %AgeGrpRates macro to create age-specific county level case rates *;
   %AgeGrpRates(&CountyName, &County_Name, Yrs0_5, 0, 6)  
   %AgeGrpRates(&CountyName, &County_Name, Yrs6_11, 6, 12)  
   %AgeGrpRates(&CountyName, &County_Name, Yrs12_17, 12, 18)  
   %AgeGrpRates(&CountyName, &County_Name, Yrs18_121, 18, 116)
   
   * Combine the four age group datasets into one county level dataset *;
   Data &County_Name._combine; 
      set &County_Name._yrs0_5   &County_Name._yrs6_11   &County_Name._yrs12_17   &County_Name._yrs18_121  ;
      proc sort data=&County_Name._combine
                  out=&County_Name._cases;
         by ReportedDate;
   run;

   * Delete age-specific datasets  *;
   proc datasets library=work NOlist ;
      delete  &County_Name._yrs0_5   &County_Name._yrs6_11   &County_Name._yrs12_17   &County_Name._yrs18_121  ;
   run;

%mend;


***  Submit %CntyRates macro for each county  ***;
***-------------------------------------------***;

%CntyRates(ADAMS)	      %CntyRates(ALAMOSA)	      %CntyRates(ARAPAHOE)	    %CntyRates(ARCHULETA)
%CntyRates(BACA)	         %CntyRates(BENT)	         %CntyRates(BOULDER)	       %CntyRates(BROOMFIELD)
%CntyRates(CHAFFEE)	      %CntyRates(CHEYENNE)	   %CntyRates(CLEAR CREEK)    %CntyRates(CONEJOS)
%CntyRates(COSTILLA)	   %CntyRates(CROWLEY)	      %CntyRates(CUSTER)	       %CntyRates(DELTA)
%CntyRates(DENVER)	      %CntyRates(DOLORES)	      %CntyRates(DOUGLAS)	       %CntyRates(EAGLE)
%CntyRates(EL PASO)	      %CntyRates(ELBERT)	      %CntyRates(FREMONT)	       %CntyRates(GARFIELD)
%CntyRates(GILPIN)	      %CntyRates(GRAND)	      %CntyRates(GUNNISON)	    %CntyRates(HINSDALE)
%CntyRates(HUERFANO)	   %CntyRates(JACKSON)	      %CntyRates(JEFFERSON)	    %CntyRates(KIOWA)
%CntyRates(KIT CARSON)	   %CntyRates(LA PLATA)	   %CntyRates(LAKE)	          %CntyRates(LARIMER)
%CntyRates(LAS ANIMAS)	   %CntyRates(LINCOLN)	      %CntyRates(LOGAN)	       %CntyRates(MESA)
%CntyRates(MINERAL)	      %CntyRates(MOFFAT)	      %CntyRates(MONTEZUMA)	    %CntyRates(MONTROSE)
%CntyRates(MORGAN)	      %CntyRates(OTERO)	      %CntyRates(OURAY)	       %CntyRates(PARK)
%CntyRates(PHILLIPS)	   %CntyRates(PITKIN)	      %CntyRates(PROWERS)	       %CntyRates(PUEBLO)
%CntyRates(RIO BLANCO)	   %CntyRates(RIO GRANDE)	   %CntyRates(ROUTT)	       %CntyRates(SAGUACHE)
%CntyRates(SAN JUAN)	   %CntyRates(SAN MIGUEL)    %CntyRates(SEDGWICK)	    %CntyRates(SUMMIT)
%CntyRates(TELLER)	      %CntyRates(WASHINGTON)	   %CntyRates(WELD)	          %CntyRates(YUMA)




***  Combine all of the County datasets into one dataset  ***;
***-------------------------------------------------------***;

Data All_County_combine; 
   set
         ADAMS_combine          ALAMOSA_combine        ARAPAHOE_combine       ARCHULETA_combine
         BACA_combine           BENT_combine           BOULDER_combine        BROOMFIELD_combine
         CHAFFEE_combine        CHEYENNE_combine       CLEAR_CREEK_combine    CONEJOS_combine
         COSTILLA_combine       CROWLEY_combine        CUSTER_combine         DELTA_combine
         DENVER_combine         DOLORES_combine        DOUGLAS_combine        EAGLE_combine
         EL_PASO_combine        ELBERT_combine         FREMONT_combine        GARFIELD_combine
         GILPIN_combine         GRAND_combine          GUNNISON_combine       HINSDALE_combine
         HUERFANO_combine       JACKSON_combine        JEFFERSON_combine      KIOWA_combine
         KIT_CARSON_combine     LA_PLATA_combine       LAKE_combine           LARIMER_combine
         LAS_ANIMAS_combine     LINCOLN_combine        LOGAN_combine          MESA_combine
         MINERAL_combine        MOFFAT_combine         MONTEZUMA_combine      MONTROSE_combine
         MORGAN_combine         OTERO_combine          OURAY_combine          PARK_combine
         PHILLIPS_combine       PITKIN_combine         PROWERS_combine        PUEBLO_combine
         RIO_BLANCO_combine     RIO_GRANDE_combine     ROUTT_combine          SAGUACHE_combine
         SAN_JUAN_combine       SAN_MIGUEL_combine     SEDGWICK_combine       SUMMIT_combine
         TELLER_combine         WASHINGTON_combine     WELD_combine           YUMA_combine        ;
run;


***  Export data to Excel file (XLS) to be used in Tableau  ***;
***---------------------------------------------------------***;

PROC EXPORT DATA= All_County_combine 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\Pediatric case rates\County data\All_County_combine.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="data"; 
RUN;


libname RFIPED 'C:\Users\eabush\Documents\GitHub\Data-requests\Pediatric case rates\County data' ; run;
DATA RFIPED.All_County_combine ; set All_County_combine; 
run;


