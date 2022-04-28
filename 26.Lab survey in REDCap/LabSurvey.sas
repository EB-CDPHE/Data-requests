/**********************************************************************************************
PROGRAM:  LabSurvey.sas
AUTHOR:   Eric Bush
CREATED:  April 28, 2022
MODIFIED: 	
PURPOSE:	 
INPUT:	      	  
OUTPUT:	 	
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;



** Create libname with XLSX engine that points to XLSX file **;
libname  RedCap   xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\26.Lab survey in REDCap\Data\SectionL_COVID_DATA_28APR22.xlsx'; run;

   proc contents data= RedCap.data  varnum ; run;


** Create SAS dataset from spreadsheet **;
DATA L_Covid;   set RedCap.data;
run;

   proc contents data= L_Covid  varnum ; run;

*** Survey Response ***;

** Number of completed surveys **;
   PROC FREQ data= L_Covid;
      tables  l_covid19_complete ;
run;


*** Survey Screener ***;
   PROC FREQ data= L_Covid;
      tables  anycovidtestingonsite * anycovidtestingoffsite  ;
run;

