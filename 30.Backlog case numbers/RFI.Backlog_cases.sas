/**********************************************************************************************
PROGRAM:  RFI.Backlog_cases.sas
AUTHOR:   Eric Bush
CREATED:  April 20, 2022
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=50 ls=150 ;     * Landscape pagesize settings *;
options ps=65 ls=110 ;     * Portrait pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;


*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA CEDRS_Backlog;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL' ;
   Keep EventID  CountyAssigned  CollectionDate  ReportedDate  CaseStatus  Outcome  Days_to_Report ;

   Days_to_Report = ReportedDate - CollectionDate;
run;

   PROC contents data=CEDRS_Backlog  varnum; title1 'CEDRS_Backlog'; run;



***  Access population data  ***;
***--------------------------***;

   PROC format;
      value RptTime
         31-high = 'More than 30d' 
          . = 'Missing'
       low - <0 = 'Negative'
            0 = '0 days'
            1 = '1 days'
            2 = '2 days'
            3 = '3 days'
            4 = '4 days'
            5 = '5 days'
            6 = '6 days'
            7 = '7 days'
         8 - 14 = '7-14 days' 
         15 - 30 = '15-30 days' ;
run;

   PROC freq data= CEDRS_Backlog;
      tables Days_to_Report;
      format Days_to_Report  RptTime. ;
run;

   PROC univariate data= CEDRS_Backlog;
      var Days_to_Report;
run;

   PROC print data= CEDRS_Backlog;
  
proc freq data= ELR_Full;
tables SpecimenID;
run;






