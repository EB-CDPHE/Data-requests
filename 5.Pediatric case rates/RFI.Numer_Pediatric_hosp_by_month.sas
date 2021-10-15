/**********************************************************************************************
PROGRAM:  RFI.Number_Pediatric_hosp_by_month.sas
AUTHOR:   Eric Bush
CREATED:  September 14, 2021
MODIFIED:	
PURPOSE:	 RFI on number of pediatric hospitalizations last year compared to now
INPUT:		COVID.CEDRS_view_fix     COPHS_fix (from COPHS_tidy)
OUTPUT:		      Ped_cases          Ped_COPHS
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

TITLE;
OPTIONS pageno=1;


   PROC contents data= COVID.CEDRS_view_fix; title1 'COVID.CEDRS_view_fix'; run;

 Data Ped_cases; set COVID.CEDRS_view_fix ;
   if (0 < Age_at_Reported < 18);

   if hospitalized=1 OR hospitalized_cophs=1 then Hosp=1;
   else Hosp=0;

   keep ProfileID  EventID  ReportedDate  Age_at_Reported  County gender  
   cophs_admissiondate  hospitalized  hospitalized_cophs    Hosp ;
run;
   PROC contents data= Ped_cases; title1 'Ped_cases'; run;

   PROC means data= Ped_cases  n nmiss ;
      var Age_at_Reported ReportedDate Hospitalized Hospitalized_COPHS ;
run;

   PROC freq data= Ped_cases ;
      table hosp * hospitalized * hospitalized_cophs / list missing missprint ;
run;

   PROC freq data= Ped_cases ;
/*      table ReportedDate * hosp / nopercent ;*/
      table ReportedDate * hospitalized_cophs / nopercent ;
      format ReportedDate  MonYY. ;
run;

proc print data= Ped_cases;
where ReportedDate>'31JUL21'd;
run;

   PROC freq data= Ped_cases ;
      where  ('01AUG20'd le ReportedDate le '31AUG20'd)  OR  ('01AUG21'd le ReportedDate le '31AUG21'd) ;
/*      table ReportedDate * hosp / nopercent ;*/
      table ReportedDate * hosp / nopercent nocol ;
      format ReportedDate  YYWeekU7. ;
run;



   PROC freq data= Ped_cases ;
      where hospitalized=1;
      table ReportedDate * hospitalized  / out=pedCEDRS ;
      format ReportedDate  MonYY. ;
run;
proc print data=pedCEDRS; run;


   PROC freq data= Ped_cases ;
      where hospitalized_cophs=1;
      table ReportedDate * hospitalized_cophs  / out=pedCOPHS ;
      format ReportedDate  MonYY. ;
run;
proc print data=pedCOPHS; run;




*** Repeat using COPHS_tidy  ***;
***__________________________***;



Data Ped_COPHS; set COPHS_fix ;
   if  0 <  INT(Intck('MONTH', DOB, Hosp_Admission)/12)  < 18;
   Age_at_Admission =  INT(Intck('MONTH', DOB, Hosp_Admission)/12) ;   

   keep MR_Number  EventID  Hosp_Admission   DOB  Age_at_Admission ;
run;

   PROC contents data= Ped_COPHS; title1 'Ped_COPHS'; run;


   PROC means data= Ped_COPHS  n nmiss ;
      var Age_at_Admission  Hosp_Admission  ;
run;

   PROC freq data= Ped_COPHS ;
      table hosp * hospitalized * hospitalized_cophs / list missing missprint ;
run;


   PROC freq data= Ped_COPHS ;
      table  Age_at_Admission Hosp_Admission ;
      format Hosp_Admission  MonYY. ;
run;
