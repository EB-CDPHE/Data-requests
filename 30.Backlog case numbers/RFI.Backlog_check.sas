/**********************************************************************************************
PROGRAM:  RFI.Backlog_check.sas
AUTHOR:   Eric Bush
CREATED:  April 22, 2022
MODIFIED:	
PURPOSE:	 One code for accessing various demographic sources for Colorado
INPUT:	      	  
OUTPUT:	 	
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;


** Create libname with XLSX engine that points to XLSX file **;
libname  BackLog  xlsx 'C:\Users\eabush\Documents\My SAS Files\Data\Report_Novel Coronavirus Listing_Excluded Backlog Output.xlsx' ; run;

   proc contents data= BackLog.data  varnum ; run;

** Create SAS dataset from spreadsheet **;
DATA BL_Excluded;   
   set BackLog.data;
   keep  ReportedDate CaseStatus ;
run;

   proc freq data= BL_Excluded;  
/*      table ReportedDate / out=BL_Excluded;  */
      table CaseStatus;  
      title1 'Report_Novel Coronavirus Listing_Excluded Backlog Output.xlsx';
run;

   proc means data= BL_Excluded  n nmiss ;
      var ReportedDate;
      title1 'Report_Novel Coronavirus Listing_Excluded Backlog Output.xlsx';
run;


/*________________________________________________________________________________________________________________________________________________________*/


libname  BackLog2  xlsx 'C:\Users\eabush\Documents\My SAS Files\Data\Report_Novel Coronavirus Listing_Original Stored Proc Output.xlsx' ; run;

   proc contents data= BackLog2.data  varnum ; run;


** Create SAS dataset from spreadsheet **;
DATA BL_Original;   
   set BackLog2.data;
   keep  ReportedDate CaseStatus ;
run;


   proc freq data= BL_Original;  
/*      table ReportedDate / out=BL_Original;  */
      table CaseStatus;  
      title1 'Report_Novel Coronavirus Listing_Original Stored Proc Output.xlsx';
run;

   proc means data= BL_Original  n nmiss ;
      var ReportedDate;
      title1 'Report_Novel Coronavirus Listing_Original Stored Proc Output.xlsx';
run;



