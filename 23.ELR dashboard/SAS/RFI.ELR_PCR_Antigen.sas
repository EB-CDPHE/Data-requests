/**********************************************************************************************
PROGRAM:  RFI.ELR_PCR_Antigen
AUTHOR:   Eric Bush
CREATED:  January 7, 2022
MODIFIED: 
PURPOSE:	 After a SQL data table has been read using Access.LabTests_TT229, 
            this program can be used to explore the SAS dataset.
INPUT:	 Lab_TT229_read
OUTPUT:	 printed output
***********************************************************************************************/
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/
options ps=65 ls=110 ;     * Portrait pagesize settings *;


*** Filter data to PCR results added since Nov 1, 2021 ***;
***-----------------------------------------------------***;
DATA ELR_PCR_filtered;  set ELR_Full;
   where DateAdded ge '01NOV21'd;

   if index(result,'POS')>0  OR result ='DETECTED' then ResultGroup='POSITIVE';
   else if index(result,'NEG')>0  OR result ='NOT DETECTED' then ResultGroup='NEGATIVE';
   else ResultGroup='UNKNOWN';

   KEEP DateAdded PatientID  COVID19negative  County  Gender  ResultGroup ;
run;

options pageno=1;
   PROC contents data=ELR_PCR_filtered  varnum ;  title1 'ELR_PCR_filtered';  run;



/*   proc freq data= ELR_Antigen;  tables result; run;*/

*** Filter data to Antigen results added since Nov 1, 2021 ***;
***--------------------------------------------------------***;
DATA ELR_Antigen_filtered;  set ELR_Antigen;
   where DateAdded ge '01NOV21'd;

   if index(result,'POS')>0  OR result ='DETECTED' then ResultGroup='POSITIVE';
   else if index(result,'NEG')>0  OR result ='NOT DETECTED' then ResultGroup='NEGATIVE';
   else ResultGroup='UNKNOWN';

   KEEP DateAdded  PatientID  Person_ID   COVID19negative  County  Gender  ResultGroup ;
run;

options pageno=1;
   PROC contents data=ELR_Antigen_filtered  varnum ;  title1 'ELR_Antigen_filtered';  run;



*** Concatenate the PCR and Antigen ELR Results ***;
***_____________________________________________***;

DATA ELR_PCR_Antigen ; 
   length Test $ 9 ;
   set ELR_PCR_filtered(in=p)  ELR_Antigen_filtered(in=a) ;
   if p then Test='PCR';  else if a then Test='Antigen';
run;

proc freq data=ELR_PCR_Antigen ; table test; run;

PROC contents data=ELR_Antigen_filtered  varnum ;  title1 'ELR_Antigen_filtered';  run;


** 8.  Move copy to DASHboard directory **;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;

DATA DASH.ELR_PCR_Antigen ; set ELR_PCR_Antigen ;
run;


