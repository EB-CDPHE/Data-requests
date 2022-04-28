/**********************************************************************************************
PROGRAM:  RFI.Backlog_check.sas
AUTHOR:   Eric Bush
CREATED:  April 22, 2022
MODIFIED: 042822	
PURPOSE:	 
INPUT:	      	  
OUTPUT:	 	
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;

/*_________________________________________________________________________________________________*
 STEPS taken by this program:
  1) Reports are placed on the K: drive in this folder:
      K:\CEDRS\CEDRS COVID Report Outputs with and without Backlog Exclusions - April 2022
  2) I move them to my hard drive to this folder:
      C:\Users\eabush\Documents\My SAS Files\Data
  3) Create libname for the two Excel workbooks
  4) See proc contents output
  5) Create SAS dataset of Excel workbooks - data tab
  6) Look at:
    a. freq distribution of cases by status
    b. overall number of cases
    c. output dataset of daily count - this gets shared
 *_________________________________________________________________________________________________*/



*** Accessing the two workbooks  ***;
***------------------------------***;

** Create libname with XLSX engine that points to XLSX file **;
libname  BackLog   xlsx 'C:\Users\eabush\Documents\My SAS Files\Data\Excluded_Backlog_Output.xlsx'; run;
libname  BackLog2  xlsx 'C:\Users\eabush\Documents\My SAS Files\Data\Original_Stored_Output.xlsx' ; run;

** Proc Contents pointing to the two workbooks **;
   proc contents data= BackLog.data  varnum ; run;
   proc contents data= BackLog2.data  varnum ; run;



*** Summary of the first workbook - Excluded  ***;
***-------------------------------------------***;

** Create SAS dataset from spreadsheet **;
DATA BL_Excluded;   
   set BackLog.data;
* if file has full complement of variables then use KEEP statement *;
/*   keep  ReportedDate CaseStatus ;*/
run;

** Get summary count by CaseStatus **;
   proc freq data= BL_Excluded;  
      table CaseStatus;  
      title1 'Report_Novel Coronavirus Listing_Excluded Backlog Output.xlsx';
run;

** Get summary count overall **;
   proc means data= BL_Excluded  n nmiss ;
      var ReportedDate;
      title1 'Report_Novel Coronavirus Listing_Excluded Backlog Output.xlsx';
run;

** Create dataset of daily counts  **;
   proc freq data= BL_Excluded;  
      table ReportedDate / out=BL_Excluded;  
      title1 'Report_Novel Coronavirus Listing_Excluded Backlog Output.xlsx';
run;


/*________________________________________________________________________________________________________________________________________________________*/


** Create SAS dataset from spreadsheet **;
DATA BL_Original;   
   set BackLog2.data;
   keep  ReportedDate CaseStatus ;
run;

** Get summary count by CaseStatus **;
   proc freq data= BL_Original;  
      table CaseStatus;  
      title1 'Report_Novel Coronavirus Listing_Original Stored Proc Output.xlsx';
run;

** Get summary count overall **;
   proc means data= BL_Original  n nmiss ;
      var ReportedDate;
      title1 'Report_Novel Coronavirus Listing_Original Stored Proc Output.xlsx';
run;

** Create dataset of daily counts  **;
   proc freq data= BL_Original;  
      table ReportedDate / out=BL_Original;  
      title1 'Report_Novel Coronavirus Listing_Original Stored Proc Output.xlsx';
run;

