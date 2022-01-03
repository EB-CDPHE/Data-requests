/**********************************************************************************************
PROGRAM:  Dashboard.CEDRS.sas
AUTHOR:   Eric Bush
CREATED:  October 22, 2021
MODIFIED:	
PURPOSE:	 Copy COVID.CEDRS dataset to Tableau dir for use in dashboards 
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;

*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;
   PROC contents data=COVID.CEDRS_view_fix varnum;  title1 'COVID.CEDRS_view_fix'; 
run;

/*proc freq data=COVID.CEDRS_view_fix  ; tables CountyAssigned ; run;*/


DATA DASH.CEDRS;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL' ;
   Keep ProfileID EventID CountyAssigned  ReportedDate  CaseStatus  Outcome  Gender  Race  Ethnicity  Age_at_Reported 
        Hospitalized  hospitalized_cophs  deathdueto_vs_u071  Reinfection  Breakthrough  outbreak_associated
        Vax_UTD  County AgeGrp  Days_since_Vax_UTD;

   County = propcase(CountyAssigned);

   If (Vax_UTD ne .) AND (ReportedDate > '31DEC20'd ) then Days_since_Vax_UTD = ReportedDate  -  Vax_UTD  ;

   if 0 le Age_at_Reported   < 5 then AgeGrp='1' ;
   else if 5 le Age_at_Reported  < 10 then AgeGrp='2' ;
   else if 10 le Age_at_Reported < 15 then AgeGrp='3' ;
   else if 15 le Age_at_Reported < 20 then AgeGrp='4' ;
   else if 20 le Age_at_Reported < 25 then AgeGrp='5' ;
   else if 25 le Age_at_Reported < 30 then AgeGrp='6' ;
   else if 30 le Age_at_Reported < 35 then AgeGrp='7' ;
   else if 35 le Age_at_Reported < 40 then AgeGrp='8' ;
   else if 40 le Age_at_Reported < 45 then AgeGrp='9' ;
   else if 45 le Age_at_Reported < 50 then AgeGrp='10';
   else if 50 le Age_at_Reported < 55 then AgeGrp='11';
   else if 55 le Age_at_Reported < 60 then AgeGrp='12';
   else if 60 le Age_at_Reported < 65 then AgeGrp='13';
   else if 65 le Age_at_Reported < 70 then AgeGrp='14';
   else if 70 le Age_at_Reported < 75 then AgeGrp='15';
   else if 75 le Age_at_Reported < 80 then AgeGrp='16';
   else if 80 le Age_at_Reported < 85 then AgeGrp='17';
   else if 85 le Age_at_Reported < 90 then AgeGrp='18';
   else if 90 le Age_at_Reported < 95 then AgeGrp='19';
   else if 95 le Age_at_Reported <120 then AgeGrp='20';
   else AgeGrp='0';  * for missing and unknown values;

run;

   PROC contents data=DASH.CEDRS  varnum; title1 'DASH.CEDRS'; run;


* CHECK the Number Hospitalized *;
   PROC freq data= DASH.CEDRS;   tables Hospitalized ;   run;



***  Access population data  ***;
***--------------------------***;

proc freq data= DASH.CEDRS; 
tables Vax_UTD * ReportedDate  / list ;  
tables  Days_since_Vax_UTD ;  
run;

proc print data= DASH.CEDRS;
where Days_since_Vax_UTD ne .;
var Vax_UTD  ReportedDate Days_since_Vax_UTD ;
run;


   PROC means data= COVID.County_Population sum  maxdec=0;
/*      where county = 'MOFFAT';*/
      var population;
run;
