/**********************************************************************************************
PROGRAM:  RFI.Memorial_Hosp_mortality_rates.sas
AUTHOR:   Eric Bush
CREATED:  October 20, 2021
MODIFIED:	
PURPOSE:	 RFI for high number of deaths at Memorial Hospital during last week
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/


**  PROC contents of starting dataset  **;
   PROC contents data= COVID.CEDRS_view_fix  varnum ; title1 'COVID.CEDRS_view_fix'; run;

DATA CEDRS_view_fix;  set COVID.CEDRS_view_fix; run;

*** Create local copy of CEDRS data for selected variables  ***;
***---------------------------------------------------------***;

DATA Memorial;  set COVID.CEDRS_view_fix;
/*   if CountyAssigned ^= 'INTERNATIONAL' ;*/
   if CountyAssigned in ('EL PASO', 'PUEBLO') ;
  Keep EventID CountyAssigned  ReportedDate  CaseStatus  Outcome
ICU LiveInInstitution gender homeless race ethnicity reinfection 
age_at_reported breakthrough outbreak_associated 
hospitalized hospitalized_cophs hospdueto_cophs_icd10 deathdueto_vs_u071 DeathDate
COPHS_AdmissionDate DateVSDeceased ;
run;

   PROC contents data=Memorial  varnum; title1 'Memorial'; run;


/*----------------------------------------------------------------------------*
 | Ended up NOT using this code. 
 |  Instead, ran Get.County_Rates.sas (which calls Macro.CountyRates.sas)
 |  for El Paso county. Used Tableau to analyze patterns.
 *----------------------------------------------------------------------------*/








***  Get population count for Moffat county  ***;
***------------------------------------------***;

   PROC means data= COVID.County_Population sum  maxdec=0;
      where county in ('EL PASO', 'PUEBLO') ;
      var population;
      class county;
run;



*** MOVE to Tableau dashboard site ***;
***--------------------------------***;

libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;

DATA MyGIT.Memorial; set Memorial;
DATA MyGIT.County_Population; set COVID.County_Population; 
      where county in ('EL PASO', 'PUEBLO') ;
run;


   PROC contents data= EL_PASO_movavg  varnum ; run; title1 'EL_PASO_movavg';

   proc freq data= EL_PASO_movavg;
      tables ReportedDate * NumDead / list ;
run;

