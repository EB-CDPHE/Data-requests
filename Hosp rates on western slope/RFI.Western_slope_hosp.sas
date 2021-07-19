/**********************************************************************************************
PROGRAM:  RFI.Western_slope_hosp
AUTHOR:   Eric Bush
CREATED:  June 22, 2021
MODIFIED: 	
PURPOSE:	 After a SQL data table has been read using Read.CEDRS_SQL_table, this program can be used to explore the SAS dataset
INPUT:	 COVID.COPHS_fix
OUTPUT:	 [name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

/*--------------------------------------------------------------------------------------------------------*
 | Table of Contents - code for the following tasks:
 |    1. Proc contents of COPHS dataset 
 |    2. Number of records with date for Hospital admit and positive COVID test (ALL records - unfiltered)
 |  --> Filter on having date for POS COVID test AND hosp admission date > 12/31/20  <--
 |    3. Create filtered dataset =  COVID_Hosp_CY21
 |    4. Number of records with date for Hospital admit and positive COVID test  (Filtered dataset)
 |    5. Hospitalizations by two regions: Western slope and ROC
 |    6. Denominator for two regions: Western slope and ROC
 |    7. Hosp count by week for CY21. Out = Admit_week_by_slope
 |       ** Admit_week_by_slope --> export to Excel for charting
 |    8. Hosp count by day for CY21. Out = Admit_day_by_slope
 |       ** Admit_day_by_slope --> export to Excel for charting |    
 |       a) Denominator for two regions of Colorado
 |    9. Time sequence of hospital dates (to learn about defining "currently hospitalized"
 |   10. Define currently hospitalized.
 |   11. Create table of currently hospitalized per 100K
 *--------------------------------------------------------------------------------------------------------*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

options pageno=1;
title1 'dphe144 = COPHS';

   PROC contents data=COVID.COPHS_fix varnum; run;


*** Descriptive analysis on ALL records (unfiltered data). ***:
***________________________________________________________***;

** 2. N and number missing in ALL records for Hosp admit date and a date for positive COVID test **;
   PROC means data= COVID.COPHS_fix  n nmiss;
      var Hosp_Admission   Positive_Test ;
run;
   PROC freq data= COVID.COPHS_fix;
      tables Positive_Test ;
      format Positive_Test MONYY. ;
run;


*** The second part of this code filters data  ***;
*** Descriptive analysis in this section is on the filtered data.                  ***:
*** Filter on CY21 only AND POS COVID test (if prior to June). Remove n=2 dups.    ***;
***________________________________________________________________________________***;

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

** 3. Create filtered dataset **;
DATA COVID_Hosp_CY21;  set COVID.COPHS;
   if Hosp_Admission > '31DEC20'd  AND  (  (Hosp_Admission<'01JUN21'd  and Positive_Test ne .) OR (Hosp_Admission ge '01JUN21'd) )   ;
   Region = put(County_of_Residence, $WestSlope. );

   * from DupChk code above ;
   if MR_Number = 'M1373870' and Facility_Name = 'West Pines Hospital' then delete;
   if MR_Number = 'M1535914' and Hosp_Admission='08NOV20'd and Facility_Name = 'West Pines Hospital' then delete;

   * from Grand county check code above ;
   if upcase(County_of_Residence) = 'GRAND' and Zip_Code in (84515, 84532, 84540) then delete;

run;
title2 'Hosp_Admission in CY21 AND Positive_Test ne . unless Hosp_Admission in June21';


** 4. FILTERED: Number of records with date for Hospital admit and positive COVID test **;
   PROC means data= COVID_Hosp_CY21  n nmiss;
      var Hosp_Admission Positive_Test;
run;


** 5. Hospitalizations by Western slope and ROC **;
   PROC freq data= COVID_Hosp_CY21;
      tables Region ;
      title3 'Hospitalizations by Western slope and ROC';
run;

** 6. Denominator for two regions of Colorado **;
   PROC means data=COVID.County_Population sum  maxdec=0 ;     * <-- see READ.Population;
      var population;
      class County;
      format County $WestSlope. ;
run;


** 7. Hosp count by week for CY21 **;
**--------------------------------**;

   /* This code is to create a dataset meant for exporting to Excel for charting */
   PROC freq data= COVID_Hosp_CY21 ;
      where Hosp_Admission < '01AUG21'd;                            * <-- to remove record with bad date;
      tables  Hosp_Admission * Region / nopercent nocum missing missprint
                                       out = Admit_week(rename= count=Admits) ;
      format Hosp_Admission WeekW5. ;
run;

** --> export Admit_week_by_slope dataset to Excel to chart **;
   proc sort data= Admit_week; by Hosp_Admission;
PROC transpose data=Admit_week(drop=PERCENT)  out=Admit_week_by_slope;
   by Hosp_Admission ;  * will create one row for each value (in this case - Week of the year);
   id Region;           * will use values of this variable for new columns;
   var Admits;          * variable to be transposed;
run;
   PROC print data= Admit_week_by_slope; 
      ID Hosp_Admission;
run; 


** 8. Hosp count by day since April 1, 2021 **;
**__________________________________________**;

  /* This code is to create a dataset meant for exporting to Excel for charting */
  PROC freq data= COVID_Hosp_CY21 noprint;
      where '30MAR21'd < Hosp_Admission < '01AUG21'd;
      tables  Hosp_Admission * Region /nopercent nocum missing missprint
                           out = Admit_day(rename= count=Admits) ;
run;
/*proc print data=Admit_by_day ; run;*/

** --> export Admit_day_by_slope dataset to Excel to chart **;
   proc sort data= Admit_day; by Hosp_Admission;
PROC transpose data=Admit_day(drop=PERCENT)  out=Admit_day_by_slope; 
   by Hosp_Admission ;  * will create one row for each value (in this case - Week of the year);
   id Region;           * will use values of this variable for new columns;
   var Admits;          * variable to be transposed;
run;
   PROC print data= Admit_day_by_slope; 
      ID Hosp_Admission;
run; 


** 9. Time sequence of selected date variables **;
   PROC print data= COVID_Hosp_CY21(obs=44);
      var Hosp_Admission  ICU_Admission  last_day_in_ICU   Date_left_facility ;
run;
/*  Seems that patients with Hosp_Admission date but have missing date for "Date_left_facility" are currently hospitalized. */


** 10. Define currently hospitalized **;
data currentHosp; set COVID_Hosp_CY21;
   if Hosp_Admission = . AND  Date_left_facility = .  then Currently_Hospitalized=.;
   else if Hosp_Admission ne . AND  Date_left_facility = . then Currently_Hospitalized=1;
   else if Hosp_Admission ne . AND  Date_left_facility < '21JUN21'd then Currently_Hospitalized=0;
   Region = put(County_of_Residence, $WestSlope. );
run;

   PROC freq data= currentHosp;
      where Currently_Hospitalized ne .;
      tables Currently_Hospitalized;
      tables Currently_Hospitalized  * Region / CMH;
run;


** 11. Create table of currently hospitalized per 100K **;
   PROC freq  data= currentHosp  noprint;
      where Currently_Hospitalized ne .;
      tables Currently_Hospitalized  * Region / out=CurrHosp;
run;

   PROC transpose data=CurrHosp(drop=PERCENT)  out=Hosp_by_slope; 
      by Region notsorted;
      id Currently_Hospitalized;
      idlabel Currently_Hospitalized;
      var  Count  ;
run;
/*proc print data=Hosp_by_slope; run;*/
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


