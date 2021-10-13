/**********************************************************************************************
PROGRAM:  RFI.Vaccination_by_age.sas
AUTHOR:   Eric Bush
CREATED:  October 22, 2021
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

title;  options pageno=1;


*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA CEDRS_fix;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  ReportedDate ge '01JAN21'd ;
   Keep ProfileID EventID CountyAssigned  ReportedDate  CaseStatus  Outcome Age_Group  Age_at_Reported Age_Years  
      Vax_UTD Vax_FirstDose Vaccine_Received Hospitalized BreakThrough Gender County;
run;

   PROC contents data=CEDRS_fix  varnum; title1 'CEDRS_CY21'; run;



***  Check data  ***;
***--------------***;

** Age vars **;
   PROC means data=CEDRS_fix  n nmiss  ;
      var  Age_at_Reported  Age_Years ;
run;

   PROC FREQ data=CEDRS_fix   ;
      tables  Age_Group;
run;

   PROC format;
      value AgeFmt
         0-<5 = '0-4'
         5-<12= '5-11'
         12-<16 = '12-15'
         16-<18 = '16-17'
         18-<30 = '18-29'
         30-<50 = '30-49'
         50-<65 = '50-64'
         65-115 = '65+' ;
run;

   PROC FREQ data=CEDRS_fix   ;
      tables  Age_at_Reported ;
      format  Age_at_Reported AgeFmt.;
run;
   proc means data=CEDRS_fix  min max; 
      var Age_Years;
      class Age_at_Reported ;
      format  Age_at_Reported AgeFmt.;
run;


** Date vars **;
   PROC means data=CEDRS_fix  n nmiss  ;
      var  ReportedDate  Vax_UTD  Vax_FirstDose ;
run;
   PROC FREQ data=CEDRS_fix   ;
      tables  Vax_UTD Vax_FirstDose ;
      format Vax_UTD Vax_FirstDose monyy.;
run;


*** County Population data ***;
***------------------------***;

   PROC contents data=COVID.County_Population;  title1 'COVID.County_Population';  run;

   PROC print data= COVID.County_Population; id county; run;



*** Create timeline of all dates ***;
***------------------------------***;

DATA timeline;
   ReportedDate='01JAN21'd;
   output;
   do t = 1 to 272;
      ReportedDate+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop t ;
run;
proc print data= timeline;  run;







***  Access population data  ***;
***--------------------------***;

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



