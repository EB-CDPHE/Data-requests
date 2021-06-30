/**********************************************************************************************
PROGRAM: EpiCurve.DeltaVOC_in_Mesa.sas
AUTHOR:  Eric Bush
CREATED: June 9, 2021
MODIFIED:  063021:  Extracted from RFI.Delta VOC in Mesa.sas	
PURPOSE:	Pull from dphe144 "CEDRS_view" and create SAS dataset for exporting to Excel to chart epi curve
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/


*** Epi curve (weekly) for Mesa County ***;
***____________________________________***;

** case count by date **;
   PROC freq data= Mesa144;
      tables ReportedDate /nopercent nocum
                           out = Cases_by_week(rename= count=CaseCount) ;
      format ReportedDate WeekW5.;
run;
/*proc print data=Cases_by_week ; run;*/


** hospital count by date **;
   PROC freq data= Mesa144;
      where Hospitalized=1;
      tables ReportedDate * Hospitalized /nopercent nocum missing missprint
                           out = Cases_Hosp_by_week(keep=ReportedDate Count) ;
      format ReportedDate WeekW5.;
run;
/*   proc print data= Cases_Hosp_by_week; run;*/


** Code below is NOT working **;
/*   proc sort data= Cases_by_week; by ReportedDate;*/
/*   proc sort data= Cases_Hosp_by_week; by ReportedDate;*/
/*Data CaseHosp; merge Cases_by_week   Cases_Hosp_by_week;*/
/*   by ReportedDate;*/
/*   proc print data=CaseHosp ; run;*/


*** Hospital data from EMR_county ***;

title1 'dphe144 - EMRcounty';

   DATA Mesa_Hosp; 
      length county $ 10;
      set Hosp144.emrcounty;
      if upcase(County)='MESA';
      format county $10.;
      Date_hosp = input(date, yymmdd10.);  format Date_hosp yymmdd10.;
run;


   PROC contents data=Mesa_Hosp varnum; run;


   proc print data=Mesa_Hosp ; 
   by Date_hosp;
   sum confirmed;
   format Date_hosp WeekW5.;
run;

   PROC means data= Mesa_Hosp sum  maxdec=0 noprint nway;
      var Confirmed ;
      class Date_hosp;
      format Date_hosp WeekW5.;
      output out=Hosp_by_week(keep=Date_Hosp Confirmed_sum)  sum=Confirmed_sum;
run;
proc print data=hosp_by_week; run;


*** pull data from cedrs_deaths_by_county ***;
DATA Mesa_deaths ;  set dbo144.cedrs_deaths_by_county ;
   if upcase(CountyAssigned)='MESA';
run;

proc means data= Mesa_deaths;

