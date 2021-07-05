/**********************************************************************************************
PROGRAM: RFI.DeltaVOC for MMWR.sas
AUTHOR:  Eric Bush
CREATED: June 9, 2021
MODIFIED:	
PURPOSE:	Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		COVID.CEDRS_view   COVID.B6172_fix   COVID.County_Population
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

/*________________________________________________________________________________________*
 | Programs to run prior to this code:
 | 1. Pull data from CEDRS using READ.CEDRS_view.  Creates COVID.CEDRS_view 
 | 2. Pull data on variants using READ.B6172.sas.  Creates work.B6172_edit
 | 3. Make edits to B6172_read using Fix.B6172.sas. Creates B6172_fix.
 | 4. MMWR.formats.sas creates formats for this program.
 *________________________________________________________________________________________*/

%inc 'C:\Users\eabush\Documents\GitHub\Data-requests\MMWR Field notes re Delta VOC\MMWR.formats.sas';

/*______________________________________________________________________________________________________________*
 | Table of contents for RFI code:
 | 1. PROC contents for 
 |    a. COVID.CEDRS_view dataset from dphe144
 |    b. work.B6172_fix dataset from dphe66
 |
 | 2. Demographics for confirmed and probable cases
 | --> filtered dataset = MESA county AND ReportedDate between April 20 - June 19, 2021 (work.Not_Mesa144)
 *______________________________________________________________________________________________________________*/


options pageno=1;

** 1. Contents of datasets to query for RFI **;
   PROC contents data=COVID.CEDRS_view varnum;
      title1 'dphe144 - CEDRS_view (a copy of CEDRS_dashboard_constrained)';
run;

 PROC contents data= COVID.B6172_fix varnum ;
      title1 'dphe66 - SQL join of several data tables';
run;


** 2. Contents of datasets to query for RFI **;
**------------------------------------------**;

DATA MMWR_cases; set COVID.CEDRS_view ;
   where '20APR21'd le CollectionDate le '19JUN21'd;
   if CountyAssigned = 'INTERNATIONAL' then delete;
   if Age_at_Reported > 109 then Age_at_Reported = .;
/*   CountyGroup = put(CountyAssigned, $MesaFmt.);*/
run;

 PROC contents data= MMWR_cases varnum ;
      title1 'COVID.CEDRS_view obs between April 20 - June 19';
run;


** 3. County Population data **;
   PROC print data= COVID.County_Population; id county; run;


** 4. Count of Cases and sum of Population by County and Age  **;
   PROC means data=MMWR_cases  maxdec=2 N nmiss  noprint ;
      var ReportedDate  ;
      class CountyAssigned  Age_at_Reported  ;
      format  CountyAssigned   $MesaFmt.  Age_at_Reported AgeFmt.;
      output out=MMWR_counts(drop=_FREQ_) n=CaseCounts;
run;
/*proc print data= MMWR_counts;  run;*/

Data MMWR_count; set MMWR_counts;
   if _TYPE_=1 then delete;
   if _TYPE_=2 then _TYPE_=1;
   rename CountyAssigned = County;
run;
/*proc print data= MMWR_count;  run;*/


   PROC means data=COVID.County_Population  maxdec=2 sum   noprint ;
      var Population  ;
      class County   ;
      format  County   $MesaFmt. ;
      output out=MMWR_pop(drop=_FREQ_) sum=PopCount;
run;
/*proc print data= MMWR_pop;  run;*/

  proc sort data= MMWR_count out=MC; by County  _TYPE_  ;
  proc sort data= MMWR_pop  out=MP;  by County  _TYPE_  ;
DATA CasesPer100; merge MC  MP ;
   by County _TYPE_;
   if PopCount ne . then CasesPer100K = (CaseCounts/ (PopCount/100000) );
   run;

   PROC print data= CasesPer100; 
      ID _TYPE_;
run;


** HOSP **;

   PROC freq data= MMWR_cases ;
      tables  CountyAssigned  Age_at_Reported hospitalized;
/*      tables CountyAssigned  * Age_at_Reported * hospitalized / nocol nopercent ;*/
     format    CountyAssigned   $MesaFmt.   Age_at_Reported AgeFmt. ;
run;



** ICU **;
/*   PROC freq data= MMWR_cases ;*/
/*     tables  ICU  ;*/
/*run;*/

   PROC freq data= COVID.CEDRS_view ;
      tables ReportedDate * ICU /list;
      format ReportedDate monyy.;
run;
/*_________________________________________________________________________________________*
 | FINDINGS:    
 | Can't use ICU variable from CEDRS_view because all values = 'Unknown' since July 2020!
 *_________________________________________________________________________________________*/











*** 3. Demographics for Colorado Cases (minus Mesa cases) ***;
***_______________________________________________________***;

options pageno=1;
title1;
title2 'County = Mesa';







