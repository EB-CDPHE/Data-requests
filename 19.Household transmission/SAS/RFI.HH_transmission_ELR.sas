/**********************************************************************************************
PROGRAM:  RFI.HH_transmission_ELR.sas
AUTHOR:   Eric Bush
CREATED:  November 10, 2021
MODIFIED: February 1, 2022	
PURPOSE:	  re-do HH transmission for Jan (start of 2nd semester)
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=50 ls=150 ;     * Landscape pagesize settings *;
options ps=65 ls=110 ;     * Portrait pagesize settings *;

title;  options pageno=1;

/*-----------------------------------------*
 | Programs to run first:
   1. Access.ELR_Full.sas
 *-----------------------------------------*/


Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;


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
