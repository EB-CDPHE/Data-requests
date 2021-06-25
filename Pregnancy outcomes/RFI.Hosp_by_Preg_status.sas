/**********************************************************************************************
PROGRAM: RFI.Hosp_by_Preg_status
AUTHOR:  Eric Bush
CREATED: June 24, 2021
MODIFIED:	
PURPOSE:	Analysis of filtered COPHS_Preg data for hosp rates by pregnancy status and region
   Target population = females, 18-40 years old
INPUT:	COVID.COPHS_Preg
OUTPUT:	COVID.COPHS_Preg
***********************************************************************************************/



* 1. Proc contents of starting datasets *;

* basic COPHS *;
   PROC contents data=COVID.COPHS varnum; run;

* expanded COPHS *;
   PROC contents data=COVID.COPHS_Preg varnum ;  run;

*** 2. Create dataset for target population from expanded COPHS: females, 18-40 years old ***;
***_______________________________________________________________________________________***;


* 2.a) Use code from Check.COPHS_Preg.sas to create temp dataset with necessary variables  *;

Data Cases_CBF_tmp ; set COVID.COPHS_Preg ;
* ignore records with DOB = Jan 1, 1990, i.e. unknown DOB ;
* ignore records with DOB during 2020 or 2021, i.e. 3 infants with COVID;
   where '01JAN1900'd < DOB < '01JAN2020'd;

* fix pregnant at admission values *;
   if Pregnant_at_Admit in ('y', 'yes') then Pregnant_at_Admit='Y';

* fix gender values *;
   if Gender='F' then Gender='Female';
   if Gender='M' then Gender='Male';

* accurate way to calculate age from two dates (per source below);
   Age_at_Admit = INT(Intck('MONTH', DOB, Hosp_Admit_Date)/12);
   If month(DOB) = month(Hosp_Admit_Date) then 
      Age_at_Admit = Age_at_Admit  -  (day(DOB)>day(Hosp_Admit_Date));
   *SOURCE: https://susanslaughter.files.wordpress.com/2010/08/61860_update_computingagesinsas.pdf ;

* For n=15 obs with missing Hosp_Admit_Date, then use ICU_Admit_date instead;
   if Hosp_Admit_Date=. then DO;
      Age_at_Admit = INT(Intck('MONTH', DOB, ICU_Admit_date)/12);
      If month(DOB) = month(ICU_Admit_date) then 
         Age_at_Admit = Age_at_Admit  -  (day(DOB)>day(ICU_Admit_date));
   END;
run;


* 2.b) Create dataset of child-bearing age females that were hospitalized with COVID19 *;


   PROC format;
      value $WestSlope
      'MOFFAT' = 'Western Slope'
      'ROUTT' =  'Western Slope'
      'JACKSON' =  'Western Slope'
      'RIO BLANCO' = 'Western Slope'
      'GRAND' =  'Western Slope'
      'GARFIELD' =  'Western Slope'
      'EAGLE' =  'Western Slope'
      'SUMMIT' =  'Western Slope'
      'MESA' =  'Western Slope'
      'PITKIN' =  'Western Slope'
      'DELTA' =  'Western Slope'
      'MONTROSE' =  'Western Slope'
      'GUNNISON' =  'Western Slope'
      'SAN MIGUEL' =  'Western Slope'
      'OURAY' =  'Western Slope'
      'HINSDALE' =  'Western Slope'
      other='Rest of Colorado' ;
run;


DATA COVID.Cases_CBF; set Cases_CBF_tmp ;
   if Gender='Female' AND (18 le Age_at_Admit le 40);

   Region = put(County_of_Residence, $WestSlope. );

   * from Grand county check code in Western_slope_hosp.sas ;
   if upcase(County_of_Residence) = 'GRAND' and Zip_Code in (84515, 84532, 84540) then delete;

run;


* COPHS for target pop *;
   PROC contents data=COVID.Cases_CBF varnum ;  run;


** freq of preg status among cases **;
   PROC freq data= COVID.Cases_CBF ;
      tables Pregnant_at_Admit ;
run;

** freq of preg status among cases by week **;
   PROC freq data= COVID.Cases_CBF ;
      tables Pregnant_at_Admit ;
run;


** ?. Hosp count by week by pregnancy status at admission - ALL COLORADO **;
**-----------------------------------------------------------------------**;

   /* This code is to create a dataset meant for exporting to Excel for charting */
   PROC freq data= COVID.Cases_CBF ;
      where Pregnant_at_Admit ne 'n/a';
      tables  Hosp_Admit_Date * Pregnant_at_Admit / nopercent nocum 
                                       out = Admit_week_by_Preg(rename= count=Admits) ;
      format Hosp_Admit_Date WeekW5. ;
run;
/*proc print data=Admit_week_by_Preg ; run;*/

** --> export Admit_week_by_slope dataset to Excel to chart **;
   proc sort data= Admit_week_by_Preg; by Hosp_Admit_Date;
PROC transpose data=Admit_week_by_Preg(drop=PERCENT)  out=Admit_week_by_PregT;
   by Hosp_Admit_Date ;  * will create one row for each value (in this case - Week of the year);
   id Pregnant_at_Admit;           * will use values of this variable for new columns;
   var Admits;          * variable to be transposed;
run;
   PROC print data= Admit_week_by_PregT; 
      ID Hosp_Admit_Date;
run; 





** ?. Hosp count by week by pregnancy status at admission - Western slope **;
**-----------------------------------------------------------------------**;

   /* This code is to create a dataset meant for exporting to Excel for charting */
   PROC freq data= COVID.Cases_CBF ;
      where Pregnant_at_Admit ne 'n/a'  AND Region='Western Slope';
      tables  Hosp_Admit_Date * Pregnant_at_Admit / nopercent nocum 
                                       out = Admit_week_by_Preg_WS(rename= count=Admits) ;
      format Hosp_Admit_Date MONYY. ;
run;
proc print data=Admit_week_by_Preg ; run;

** --> export Admit_week_by_slope dataset to Excel to chart **;
   proc sort data= Admit_week_by_Preg_WS; by Hosp_Admit_Date;
PROC transpose data=Admit_week_by_Preg_WS(drop=PERCENT)  out=Admit_week_by_Preg_WST;
   by Hosp_Admit_Date ;  * will create one row for each value (in this case - Week of the year);
   id Pregnant_at_Admit;           * will use values of this variable for new columns;
   var Admits;          * variable to be transposed;
run;
   PROC print data= Admit_week_by_Preg_WST; 
      ID Hosp_Admit_Date;
run; 





