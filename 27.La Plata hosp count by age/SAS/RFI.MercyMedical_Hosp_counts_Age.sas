/**********************************************************************************************
PROGRAM:  RFI.Mercy_Hosp_counts_Age.sas
AUTHOR:   Eric Bush
CREATED:  March 4, 2022
MODIFIED:	
PURPOSE:	 Prep curated and edited COPHS data for use in Tableau 
          to calculate count of hospitalizations by age in La Plata 
INPUT:	 COVID.COPHS_fix     	  
OUTPUT:	 DASH.COPHS_fix	
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;


 * Programs run prior to this one *;
/*--------------------------------*
 | 1. Access.COPHS.sas
 | 2. Check.COPHS.sas
 | 3. Fix.COHPS.sas
 *--------------------------------*/


*** How many COPHS records are for patients in La Plata county? ***;
***-------------------------------------------------------------***;

   PROC freq data= COVID.COPHS_fix; tables Facility_Name; run;

DATA COPHS_Mercy;   set COVID.COPHS_fix;
   where Facility_Name = 'Mercy Medical Center'
   AND ('01MAR2020'd  le  Hosp_Admission le  '22FEB2022'd)  ;

* accurate way to calculate age from two dates (per source below);
   Age_at_Admit = INT(Intck('MONTH', DOB, Hosp_Admission)/12);
   If month(DOB) = month(Hosp_Admission) then 
      Age_at_Admit = Age_at_Admit  -  (day(DOB)>day(Hosp_Admission));
   *SOURCE: https://susanslaughter.files.wordpress.com/2010/08/61860_update_computingagesinsas.pdf ;

run;




options ps=65 ls=110 ;     * Portrait pagesize settings *;
   PROC print data = COPHS_Mercy ;
      id MR_Number;  var   Facility_Name DOB  Age_at_Admit  Last_Name  First_Name  Gender City County_of_Residence    
         Hosp_Admission  ICU_Admission  Invasive_Ventilator ;
      format   City   First_Name  $10.   Last_Name    Discharge_Transfer_Death_Disposi $20.  Facility_Name $40. ;
run;


   PROC freq data= COPHS_Mercy; 
      tables DOB  Age_at_Admit ; 
run;





*** Copy COPHS data to dashboard directory ***;
***----------------------------------------***;

DATA DASH.COPHS_Mercy; set COPHS_Mercy;
run;




