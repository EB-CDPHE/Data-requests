/**********************************************************************************************
PROGRAM:  Get.County_rates.sas
AUTHOR:   Eric Bush
CREATED:  September 20, 2021
MODIFIED:	
PURPOSE:	 RFI on creating chart that compares case rate (7d mov avg) for NOCO vs CO
INPUT:	 COVID.County_Population   COVID.CEDRS_view_fix	
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

/*____________________________________________*
 | Programs to run prior to this one:
 | --> run Access.CEDRS_view
 | --> run Access.zDSI.Events
 | --> run Fix.zDSI.Events
 | --> run Fix.CEDRS_view
 *____________________________________________*/


/*___________________________________________________________________________________*
 | Table of Contents:
 | 1. County population data
 | 2. Create timeline of all outbreak dates
 | 3. Create local copy of CEDRS case data for selected variables
 | 4. Calculate Colorado rates (case rate, 7d mov avg, hosp rate, COPHS hosp rate
 | 5. MACRO to calculate County rates
 | 6. 
 | 7. MACRO Template (for LARIMER COUNTY)
 *___________________________________________________________________________________*/


TITLE;
OPTIONS pageno=1;

*** County Population data ***;
***------------------------***;

   PROC contents data=COVID.County_Population;  title1 'COVID.County_Population';  run;

   PROC print data= COVID.County_Population; id county; run;



*** Create timeline of all dates ***;
***------------------------------***;

DATA timeline;
   ReportedDate='01MAR20'd;
   output;
   do t = 1 to 570;
      ReportedDate+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop t ;
run;
proc print data= timeline;  run;



*** Create local copy of CEDRS case data for selected variables  ***;
***--------------------------------------------------------------***;

DATA CEDRS_view_fix;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL' ;
   keep ProfileID  EventID  ReportedDate  Age_at_Reported  County  hospitalized  hospitalized_cophs ;
run;

   PROC contents data=CEDRS_view_fix varnum ;  title1 'CEDRS_view_fix';  run;



*** Colorado - ALL Counties ***:
***-------------------------***;

** Set population for Colorado **;
   PROC means data= COVID.County_Population  sum  noprint;
      var population ;
      output out=CO_Pop sum=population;
run;
/*   proc print data= CO_Pop; run;*/

data _null_; set CO_Pop; 
   call symputx("ColoPop", population);    * <-- put population value into macro variable;
run;

**  Create age specific dataset and sort by date  **;
  PROC sort data=CEDRS_view_fix  
             out= CEDRS_view_sort; 
      by ReportedDate;
run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Colorado_rate; set CEDRS_view_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then DO;  NumCases=0;  NumHosp=0;  NumCOPHS=0;  END;
      NumCases+1;
      NumHosp+hospitalized;
      NumCOPHS+hospitalized_cophs;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate=  NumCases / (&ColoPop/100000);
      HospRate=  NumHosp  / (&ColoPop/100000);
      COPHSRate= NumCOPHS / (&ColoPop/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  hospitalized  hospitalized_cophs   ;
run;
/*   proc print data= Colorado_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Colorado_dates;  merge Timeline  Colorado_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if NumHosp=. then NumHosp=0 ; 
   if NumCOPHS=. then NumCOPHS=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   if HospRate=. then HospRate=0 ; 
   if COPHSRate=. then COPHSRate=0 ; 

*add vars to describe population (will be missing for obs from Timeline only) *;
   County="ALL";  

run;

**  Calculate 7-day moving averages  **;
   PROC expand data=Colorado_dates   out=Colorado_MovingAverage  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
      convert HospRate=Hosp7dAv / transformout=(movave 7);
      convert COPHSRate=COPHS7dAv / transformout=(movave 7);
run;



*** MACRO to calculate County rates ***:
***---------------------------------***;

** Run macro **;

/*%inc 'C:\Users\eabush\Documents\My SAS Files\Code\macro.CountyRates.sas' ;*/


** Selected County  **;

%CountyRates(LARIMER)


***  ALL Counties ***;
***---------------***;

%CountyRates(ADAMS)	       %CountyRates(ALAMOSA)	      %CountyRates(ARAPAHOE)	       %CountyRates(ARCHULETA)
%CountyRates(BACA)	       %CountyRates(BENT)	         %CountyRates(BOULDER)	       %CountyRates(BROOMFIELD)
%CountyRates(CHAFFEE)	    %CountyRates(CHEYENNE)	   %CountyRates(CLEAR CREEK)     %CountyRates(CONEJOS)
%CountyRates(COSTILLA)	    %CountyRates(CROWLEY)	      %CountyRates(CUSTER)	       %CountyRates(DELTA)
%CountyRates(DENVER)	    %CountyRates(DOLORES)	      %CountyRates(DOUGLAS)	       %CountyRates(EAGLE)
%CountyRates(EL PASO)	    %CountyRates(ELBERT)	      %CountyRates(FREMONT)	       %CountyRates(GARFIELD)
%CountyRates(GILPIN)	    %CountyRates(GRAND)	      %CountyRates(GUNNISON)	       %CountyRates(HINSDALE)
%CountyRates(HUERFANO)	    %CountyRates(JACKSON)	      %CountyRates(JEFFERSON)	    %CountyRates(KIOWA)
%CountyRates(KIT CARSON)	 %CountyRates(LA PLATA)	   %CountyRates(LAKE)	          %CountyRates(LARIMER)
%CountyRates(LAS ANIMAS)	 %CountyRates(LINCOLN)	      %CountyRates(LOGAN)	          %CountyRates(MESA)
%CountyRates(MINERAL)	    %CountyRates(MOFFAT)	      %CountyRates(MONTEZUMA)	    %CountyRates(MONTROSE)
%CountyRates(MORGAN)	    %CountyRates(OTERO)	      %CountyRates(OURAY)	          %CountyRates(PARK)
%CountyRates(PHILLIPS)	    %CountyRates(PITKIN)	      %CountyRates(PROWERS)	       %CountyRates(PUEBLO)
%CountyRates(RIO BLANCO)	 %CountyRates(RIO GRANDE)	   %CountyRates(ROUTT)	          %CountyRates(SAGUACHE)
%CountyRates(SAN JUAN)	    %CountyRates(SAN MIGUEL)    %CountyRates(SEDGWICK)	       %CountyRates(SUMMIT)
%CountyRates(TELLER)	    %CountyRates(WASHINGTON)	   %CountyRates(WELD)	          %CountyRates(YUMA)



***  Combine all of the County datasets into one dataset  ***;
***-------------------------------------------------------***;

Data All_County_movavg; 
   set
         ADAMS_movavg          ALAMOSA_movavg        ARAPAHOE_movavg       ARCHULETA_movavg
         BACA_movavg           BENT_movavg           BOULDER_movavg        BROOMFIELD_movavg
         CHAFFEE_movavg        CHEYENNE_movavg       CLEAR_CREEK_movavg    CONEJOS_movavg
         COSTILLA_movavg       CROWLEY_movavg        CUSTER_movavg         DELTA_movavg
         DENVER_movavg         DOLORES_movavg        DOUGLAS_movavg        EAGLE_movavg
         EL_PASO_movavg        ELBERT_movavg         FREMONT_movavg        GARFIELD_movavg
         GILPIN_movavg         GRAND_movavg          GUNNISON_movavg       HINSDALE_movavg
         HUERFANO_movavg       JACKSON_movavg        JEFFERSON_movavg      KIOWA_movavg
         KIT_CARSON_movavg     LA_PLATA_movavg       LAKE_movavg           LARIMER_movavg
         LAS_ANIMAS_movavg     LINCOLN_movavg        LOGAN_movavg          MESA_movavg
         MINERAL_movavg        MOFFAT_movavg         MONTEZUMA_movavg      MONTROSE_movavg
         MORGAN_movavg         OTERO_movavg          OURAY_movavg          PARK_movavg
         PHILLIPS_movavg       PITKIN_movavg         PROWERS_movavg        PUEBLO_movavg
         RIO_BLANCO_movavg     RIO_GRANDE_movavg     ROUTT_movavg          SAGUACHE_movavg
         SAN_JUAN_movavg       SAN_MIGUEL_movavg     SEDGWICK_movavg       SUMMIT_movavg
         TELLER_movavg         WASHINGTON_movavg     WELD_movavg           YUMA_movavg        ;
run;


**  Save combined dataset to Dashboard data directory (for Tableau)  **;

libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;

DATA DASH.All_County_movavg ;  set All_County_movavg; 
run;

DATA DASH.CO_County_movavg; set  Colorado_MovingAverage   All_County_movavg;
run;




** view data **;
/*   PROC print data= Larimer_MovAvg;  title1 'Larimer_MovAvg';  run;*/





*** MACRO Template (for LARIMER COUNTY) ***:
***-------------------------------------***;

** Set population for age group **;
data _null_; set COVID.County_Population; 
   where County = 'LARIMER' ;

   call symputx("CntyPop", population);    * <-- put number from county population into macro variable;
run;

**  Create age specific dataset and sort by date  **;
 Data CEDRS_Larimer; set CEDRS_view_fix ;
   where County = 'LARIMER' ;
run;

  PROC sort data=CEDRS_Larimer  
             out= Larimer_sort; 
      by ReportedDate;
run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data Larimer_rate; set Larimer_sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then DO;  NumCases=0;  NumHosp=0;  NumCOPHS=0;  END;
   NumCases+1;
   NumHosp+1;
   NumCOPHS+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&CntyPop/100000);
      HospRate= NumHosp / (&CntyPop/100000);
      COPHSRate= NumCOPHS / (&CntyPop/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  hospitalized  hospitalized_cophs   ;
run;
/*   proc print data= Larimer_rate ;  ID ReportedDate ;  run;*/

** add ALL reported dates for populations with sparse data **;
Data Larimer_dates; merge Timeline  Larimer_rate;
   by ReportedDate;

* backfill missing with 0 and add vars to describe population *;
   if NumCases=. then NumCases=0 ; 
   if NumHosp=. then NumHosp=0 ; 
   if NumCOPHS=. then NumCOPHS=0 ; 
   if CaseRate=. then CaseRate=0 ; 
   if HospRate=. then HospRate=0 ; 
   if COPHSRate=. then COPHSRate=0 ; 

*add vars to describe population (will be missing for obs from Timeline only) *;
   County="Larimer";  

run;
/*   proc print data= Larimer0_115_dates ;  ID ReportedDate ;  run;*/


**  Calculate 7-day moving averages  **;
   PROC expand data=Larimer_dates   out=Larimer_MovingAverage  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
      convert HospRate=Hosp7dAv / transformout=(movave 7);
      convert COPHSRate=COPHS7dAv / transformout=(movave 7);
run;

/*   PROC print data= Larimer_MovingAverage;  title1 'Larimer_MovingAverage';  run;*/
