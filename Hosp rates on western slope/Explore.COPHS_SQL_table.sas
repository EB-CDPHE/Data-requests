/**********************************************************************************************
PROGRAM: Explore.COPHS
AUTHOR:  Eric Bush
CREATED: June 22, 2021
MODIFIED:	
PURPOSE:	After a SQL data table has been read using Read.CEDRS_SQL_table, this program can be used to explore the SAS dataset
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

/*________________________________________________________________________________________________________*
 | Table of Contents - code for the following tasks:
 |    1. Proc contents of COPHS dataset
 |    2. Identify duplicate records. 
 |    3. Print selected variables for duplicate records.
 |    4. Number of records with a date for positive COVID test
 |  --> Filter on having date for POS COVID test AND hosp admission date > 12/31/20  <--
 |    5. Proc contents of filtered COPHS dataset =  COVID_Hosp_CY21
 |    6. Hospitalizations by Western slope and ROC
 |    7. Hosp count by week for CY21. Out = Admit_week_by_slope
 |       ** Admit_week_by_slope --> export to Excel for charting
 |    8. Hosp count by day for CY21. Out = Admit_day_by_slope
 |       ** Admit_day_by_slope --> export to Excel for charting |    C. Explore Demographic variables.
 |    9. Time sequence of hospital dates (to learn about defining "currently hospitalized"
 |   10. Create table of currently hospitalized per 100K
 *________________________________________________________________________________________________________*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

options pageno=1;
title1 'dphe144 = COPHS';
   PROC contents data=COVID.COPHS varnum; run;

* 2: Identify duplicate records *;
   PROC FREQ data= COVID.COPHS  noprint;  
      tables MR_Number / out=DupChk(where=(COUNT>1));
/*   PROC print data=DupChk;  id MR_Number; var Count;  run;*/

* 3: Print out dup records  *;
   proc sort data=COVID.COPHS(drop=filename)  out=COPHSdups  ; by MR_Number; run;
   proc sort data=DupChk  ; by MR_Number; run;
DATA ChkCOPHSdups; merge COPHSdups DupChk(in=dup) ; 
   by MR_Number; 
   if dup;
run;

options ps=50 ls=150 ;     * Landscape pagesize settings *;

   PROC print data=ChkCOPHSdups ; 
      var MR_Number Facility_Name Last_Name Gender Invasive_ventilator__Y_N_   Current_Level_of_care   Discharge_Transfer_Death_Disposi
         Hosp_Admission ICU_Admission Date_Left_Facility Last_Day_in_ICU Count;
      format Discharge_Transfer_Death_Disposi $20. Facility_Name $40. ;
title2 'List of dup records';
run;


options ps=65 ls=110 ;     * Portrait pagesize settings *;
title2;

** 4. Number of records with a date for positive COVID test **;
   PROC means data= COVID.COPHS  n nmiss;
      var Positive_Test;
run;
   PROC freq data= COVID.COPHS;
      tables Positive_Test ;
      format Positive_Test MONYY. ;
run;


*** Filter on POS COVID test AND CY21 only ***;
***----------------------------------------***;

DATA COVID_Hosp_CY21;  set COVID.COPHS;
   if Positive_Test ne .  AND  Hosp_Admission > '31DEC20'd ;
run;
title2 'Positive_Test ne .  AND  Hosp_Admission > 31DEC20';

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

** Hospitalizations by Western slope and ROC **;
   PROC freq data= COVID_Hosp_CY21;
      tables County_of_Residence /missing missprint;
      FORMAT County_of_Residence $WestSlope. ;
      title3 'Hospitalizations by Western slope and ROC';
run;

** Hosp count by week for CY21 **;
   PROC freq data= COVID_Hosp_CY21 noprint;
      where Hosp_Admission < '01AUG21'd;
      tables  Hosp_Admission * County_of_Residence / nopercent nocum missing missprint
                           out = Admit_week(rename= count=Admits) ;
      format Hosp_Admission WeekW5.  County_of_Residence $WestSlope.;
run;
/*proc print data=Admit_by_week ; run;*/

** --> export Admit_week_by_slope dataset to Excel to chart **;
   PROC transpose data=Admit_week(drop=PERCENT)  out=Admit_week_by_slope; 
      by Hosp_Admission notsorted;
   /*   id County_of_Residence;*/
   /*  idlabel County_of_Residence;*/
      var Admits;
run;
DATA Admit_week_by_slope; set Admit_week_by_slope;
   if Hosp_Admission < '01AUG21'd;
   rename col1=ROC;
   rename col2=West_Slope;
run;
   PROC print data=Admit_week_by_slope ; 
      ID Hosp_Admission;
run;  


** Hosp count by day since April 1, 2021 **;
   PROC freq data= COVID_Hosp_CY21 noprint;
      where '30MAR21'd < Hosp_Admission < '01AUG21'd;
      tables  Hosp_Admission * County_of_Residence /nopercent nocum missing missprint
                           out = Admit_day(rename= count=Admits) ;
      format  County_of_Residence $WestSlope.;
run;
/*proc print data=Admit_by_day ; run;*/

** --> export Admit_day_by_slope dataset to Excel to chart **;
proc transpose data=Admit_day(drop=PERCENT)  out=Admit_day_by_slope; 
   by Hosp_Admission notsorted;
/*   id County_of_Residence;*/
/*  idlabel County_of_Residence;*/
   var Admits;
run;
DATA Admit_day_by_slope; set Admit_day_by_slope;
   rename col1=ROC;
   rename col2=West_Slope;
run;
   proc print data=Admit_day_by_slope ; run;



** 9. Time sequence of selected date variables **;
   PROC print data= COVID_Hosp_CY21(obs=44);
      var Hosp_Admission  ICU_Admission  last_day_in_ICU   Date_left_facility ;
run;

data currentHosp; set COVID_Hosp_CY21;
   if Hosp_Admission = . AND  Date_left_facility = .  then Currently_Hospitalized=.;
   else if Hosp_Admission ne . AND  Date_left_facility = . then Currently_Hospitalized=1;
   else if Hosp_Admission ne . AND  Date_left_facility < '21JUN21'd then Currently_Hospitalized=0;
   Region = put(County_of_Residence, $WestSlope. );
run;

   PROC freq data= currentHosp;
      where Currently_Hospitalized ne .;
      tables Currently_Hospitalized;
      tables Currently_Hospitalized  * Region /missing missprint out=Hosp;
run;


** 10. Create table of currently hospitalized per 100K **;
   PROC transpose data=Hosp(drop=PERCENT)  out=Hosp_by_slope; 
      by Region notsorted;
      id Currently_Hospitalized;
      idlabel Currently_Hospitalized;
      var  Count  ;
run;
proc print data=Hosp_by_slope; run;
/*proc contents data=Hosp_by_slope; run;*/


DATA CurrHosp100k; set Hosp_by_slope(drop=_0);
   where _1 ne .;
   rename _1 = Current_Hosp;
   if Region = 'Western Slope' then Pop= 486582;
   if Region = 'Rest of Colorado'  then Pop= 16805347;
   Hosp_per_100k = (_1/Pop)*100000;
   label Hosp_per_100k = 'Current Hospitalizations per 100K';
run;
   PROC print data= CurrHosp100k l; 
      id Region;
      var Hosp_per_100k;
run;


