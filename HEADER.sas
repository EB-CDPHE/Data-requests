/**********************************************************************************************
PROGRAM:  HEADER.sas
AUTHOR:   Eric Bush
CREATED:  October 22, 2021
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;

*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA CEDRS_fix;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL' ;
   Keep EventID CountyAssigned  ReportedDate  CaseStatus  Outcome;
run;

   PROC contents data=CEDRS_fix  varnum; title1 'CEDRS_fix'; run;



***  Access population data  ***;
***--------------------------***;

   PROC means data= COVID.County_Population sum  maxdec=0;
/*      where county = 'MOFFAT';*/
      var population;
run;
