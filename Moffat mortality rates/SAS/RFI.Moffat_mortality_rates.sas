/**********************************************************************************************
PROGRAM:  RFI.Moffat_mortality_rates.sas
AUTHOR:   Eric Bush
CREATED:  October 7, 2021
MODIFIED:	
PURPOSE:	 RFI for mortality rates in Moffat (vs CO) for two time periods
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/


*** Create local copy of CEDRS data for selected variables  ***;
***---------------------------------------------------------***;

DATA CEDRS_fix;  set COVID.CEDRS_view_fix;
   if CountyAssigned = "MOFFAT";
   Keep EventID CountyAssigned  ReportedDate  CaseStatus  Outcome;
run;

   PROC contents data=CEDRS_fix  varnum; title1 'CEDRS_fix'; run;



***  Get population count for Moffat county  ***;
***------------------------------------------***;

   PROC means data= COVID.County_Population sum  maxdec=0;
      where county = 'MOFFAT';
      var population;
run;


*** Calculate mortality rate (per 100K) for Moffat county  ***;
***--------------------------------------------------------***;

title1 'COVID.CEDRS_view_fix';
title2 'CountyAssigned = "MOFFAT"';

title3 'ALL dates';
   PROC freq data= CEDRS_fix noprint;
      where CountyAssigned = "MOFFAT";
      tables Outcome / out=Moffat_Sum1;
run;
DATA Moffat_ALL  ; set Moffat_Sum1;
      Mortality_Rate_ALL = COUNT / (13252 / 100000) ; 
run;
   PROC print data= Moffat_ALL; 
run;


title3 "ReportedDate ge '01JUN21'd";
   PROC freq data= CEDRS_fix noprint;
      where CountyAssigned = "MOFFAT"  AND  ReportedDate ge '01JUN21'd;
      tables Outcome /out=Moffat_Sum2;
run;
DATA Moffat_June ; set Moffat_Sum2;
      Mortality_Rate_June = COUNT / (13252 / 100000) ; 
run;
   PROC print data= Moffat_June; 
run;



***  Get population count for Colorado  ***;
***-------------------------------------***;

   PROC means data= COVID.County_Population sum  maxdec=0;
      var population;
run;


*** Calculate mortality rate (per 100K) for Colorado  ***;
***---------------------------------------------------***;

title1 'COVID.CEDRS_view_fix';
title2 'CountyAssigned = "ALL"';

title3 'ALL dates';
   PROC freq data= CEDRS_fix noprint;
      tables Outcome /out=CO_Sum1;
run;
DATA CO_ALL  ; set CO_Sum1;
      Mortality_Rate_ALL = COUNT / (5763976 / 100000) ; 
run;
   PROC print data= CO_ALL; 
run;


title3 "ReportedDate ge '01JUN21'd";
   PROC freq data= CEDRS_fix noprint;
      where ReportedDate ge '01JUN21'd;
      tables Outcome /out=CO_Sum2;
run;
DATA CO_June  ; set CO_Sum2;
      Mortality_Rate_June = COUNT / (5763976 / 100000) ; 
run;
   PROC print data= CO_June; 
run;
