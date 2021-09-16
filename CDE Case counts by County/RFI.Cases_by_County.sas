/**********************************************************************************************
PROGRAM:  RFI.Cases_by_County.sas
AUTHOR:   Eric Bush
CREATED:  September 16, 2021
MODIFIED: 
PURPOSE:	 Data request from CDE re: case rates by county for all time and FY20-21
INPUT:	 COVID.CEDRS_view_fix   COVID.County_Population  
OUTPUT:	 datasets --> CSV files
***********************************************************************************************/

** Access the CEDRS.view using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** contains "CEDRS_view which is copy of CEDRS_dashboard_constrained";

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

DATA CED; 
   set COVID.CEDRS_view_fix(keep=ProfileID EventID  Age_Group CountyAssigned CaseStatus Vax_UTD 
                             Age_at_Reported hospitalized  ReportedDate CollectionDate County);

   if CountyAssigned = 'INTERNATIONAL' then delete;

run;

   PROC contents data=CED varnum ; title1 'CEDRS_view_fix'; run;
   PROC means data=CED n nmiss ; 
      var Age_at_Reported hospitalized ReportedDate CollectionDate  ;
run;

   PROC freq data=CED;
      tables County ;
run;


/*----------------------------------------------------------------------------*
 | The county level population data is created via Access.Populations.sas
 *----------------------------------------------------------------------------*/

** County Population data **;
   PROC contents data=COVID.County_Population; run;

/*   PROC print data= COVID.County_Population; id county; run;*/

   PROC means data= COVID.County_Population sum  maxdec=0;
      var population;
      class county;
run;


Data All_Pop; length County $13; set COVID.County_Population;
   keep County Population;
run;


** Total Cases by county - ALL dates **;
**-----------------------------------**;

** Calculate case counts by county **;
   PROC means data=CED  maxdec=2 N nmiss  nway ;*noprint ;
      var ReportedDate  ;
      class   County  ;
      output out=ALL_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
run;

** Calculate case rate per 100K by county **;
   proc sort data= All_Cases; by County; run;
   proc sort data=All_Pop ; by County; run;
Data All_CaseRate; merge All_Cases  All_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   Age_Group='ALL';
run;

** Merge population data and case rates by county **;
   proc sort data=All_CaseRate
               out=All_CaseRate_sort ;
      by descending CasesPer100K ;
proc print data=All_CaseRate_sort ; 
   id County; var CasesPer100K CaseCounts Population  ;
   format CasesPer100K comma7.0 ;
   sum CaseCounts;
run;


** Total Cases by county - July 1, 2020 to June 30, 2021 **;
**-------------------------------------------------------**;

** Calculate case counts by county **;
   PROC means data=CED  maxdec=2 N nmiss  nway noprint ;
      where '01JUL20'd le ReportedDate le '30JUN21'd ;
      var ReportedDate  ;
      class   County  ;
      output out=FY20_21_Cases(drop=_FREQ_ _TYPE_) n=CaseCounts;
run;

** Calculate case rate per 100K by county **;
   proc sort data= FY20_21_Cases; by County; run;
   proc sort data=All_Pop ; by County; run;
Data FY20_21_CaseRate; merge FY20_21_Cases  All_Pop;  by county;
   CasesPer100K = (CaseCounts/ (Population/100000) );
   TimeRef='FY20-21';
run;

** Merge population data and case rates by county **;
   proc sort data=FY20_21_CaseRate
               out=FY20_21_CaseRate_sort ;
      by descending CasesPer100K ;
proc print data=FY20_21_CaseRate_sort ; 
   id County; var CasesPer100K CaseCounts Population TimeRef ;
   format CasesPer100K comma7.0 ;
   sum CaseCounts;
run;




 





