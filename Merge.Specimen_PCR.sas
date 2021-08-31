/**********************************************************************************************
PROGRAM: Merge.Specimen_PCR
AUTHOR:  Eric Bush
CREATED:	August 31, 2021
MODIFIED: 
PURPOSE:	Make data edits to Lab_TT437_read per edit checks in CHECK.LabTests_TT437.sas
INPUT:	      Specimens_read      Lab_TT229_fix 
OUTPUT:	      Specimens_w_PCR
***********************************************************************************************/


*** STEP 1:  Merge PCR LabTests data with Specimen data ***;
***-----------------------------------------------------***;
   proc sort data= Specimens_read
               out= Specimens_sort;
      by LabSpecimenID EventID;
run;

DATA Specimens_w_PCR; 
   merge Lab_TT229_fix(in=pcr)  Specimens_read ;
   by LabSpecimenID EventID;
   if pcr=1;            * <--  KEEP only the specimen records that have had a PCR test;
run;

   PROC contents data=Specimens_w_PCR  varnum ;  title1 'Specimens_w_PCR';  run;


*** STEP 2:  Merge COVID sequencing LabTests data  ***;
***------------------------------------------------***;

DATA COVID_Sequence ; 
   merge Lab_TT437_fix(in=TT437)  Lab_TT436_fix;
   by LabSpecimenID EventID;

   if TT437;
run;

   PROC contents data=COVID_Sequence  varnum ;  title1 'COVID_Sequence';  run;
