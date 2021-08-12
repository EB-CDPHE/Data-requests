/**********************************************************************************************
PROGRAM: CEDRS_Data_Validation
AUTHOR:  Eric Bush
CREATED: July 22, 2021
MODIFIED:	
PURPOSE:	Comprehensive list of data checks for CEDRS view
INPUT:	CEDRS_view_read
OUTPUT:	printed output
***********************************************************************************************/

**  Read fresh copy of the CEDRS_view data table from dphe144  **;
%inc 'C:\Users\eabush\Documents\GitHub\Data-requests\Access.CEDRS_view.sas';

**  Place name of dataset to validate into macro variable  **;
%LET ChkDSN = 'CEDRS_view_read';       * <-- ENTER name of CEDRS dataset to run data checks against;

**  Contents of dataset to validate  **;
   PROC contents data= CEDRS_view_read varnum; run;

**  Age variables  **;
   PROC freq data= CEDRS_view_read;
      tables Age_Group  Age_at_Reported ; 
run;

/*---*
 | Findings:
 | Why have an Age_Group variable? Keep continous variable instead.
 *---*/

   PROC format;
      value AgeFmt
         0 - 9 = '0-9'
         10 - 19 = '10-19'
         20 - 29 = '20-29'
         30 - 39 = '30-39'
         40 - 49 = '40-49'
         50 - 59 = '50-59'
         60 - 69 = '60-69'
         70 - 79 = '70-79'
         80-high = '80+'  ;
run;

