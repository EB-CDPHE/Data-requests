/**********************************************************************************************
PROGRAM:  RFI.Hosp_admit.chart.sas
AUTHOR:   Eric Bush
CREATED:  September 10, 2021
MODIFIED:	
PURPOSE:	 RFI for chart of hospital admission rates (daily count and 7 d avg) 
INPUT:		COVID.COPHS_fix   
OUTPUT:		Hosp_Admit_MoveAv
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

**  Access the folder with the final SAS dataset to be used in this code  **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

options pageno=1;

** 1. Contents of SOURCE dataset to query for RFI **;
   PROC contents data=COVID.COPHS_fix varnum; 
      title1 'dphe144 = COPHS';
run;

** 2. N and number missing in ALL records for Hosp admit date and a date for positive COVID test **;
   PROC means data= COVID.COPHS_fix  n nmiss;
      var Hosp_Admission   Positive_Test ;
run;


** 3. Create dataset for analysis **;
DATA COPHS_RFI; set COVID.COPHS_fix(KEEP=MR_Number Hosp_Admission Positive_Test UTD  facility_name) ;
   Admit_Date = Hosp_Admission;
   format Admit_Date MMDDYY10. ;
run;
** 4. Contents of datasets to query for RFI **;
   PROC contents data=COPHS_RFI varnum; 
      title1 'dphe144 = COPHS_FIX reduced';
run;


** Daily count of hospital admissions **;
   PROC FREQ data= COPHS_RFI;
      where '01MAR20'd le Admit_Date le '10SEP21'd ;
      tables Admit_Date / out=Hosp_Admit_Count; 
run;
   PROC print data= Hosp_Admit_Count;
run;


*** Create timeline of all dates ***;
***------------------------------***;

DATA timeline;
   Admit_Date='01MAR20'd;
   output;
   do t = 1 to 560;
      Admit_Date+1;
      output;
   end;
   format Admit_Date mmddyy10.;
   drop t ;
run;
proc print data= timeline;  run;


** Merge Timeline so have full calendar **;
DATA Hosp_Admit_ALLdates ;
   merge Hosp_Admit_Count  timeline ;
   by Admit_Date ;
run;
   proc print data= Hosp_Admit_ALLdates; id Admit_Date; run;

**  Calculate 7-day moving averages  **;
   PROC expand data=Hosp_Admit_ALLdates   out=Hosp_Admit_MoveAv  method=none;
      id Admit_Date;
      convert COUNT=Admits7dAv / transformout=(movave 7);
run;
   PROC print data= Hosp_Admit_MoveAv;
run;


