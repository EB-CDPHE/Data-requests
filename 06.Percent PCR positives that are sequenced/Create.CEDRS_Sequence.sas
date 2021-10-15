/********************************************************************************************************
PROGRAM:  Create.CEDRS_Sequence
AUTHOR:   Eric Bush
CREATED:	 August 31, 2021
MODIFIED: 090121
PURPOSE:	 Make data edits to Lab_TT437_read per edit checks in CHECK.LabTests_TT437.sas
INPUT:	 Specimens_reduced  &  Lab_TT229_fix  |_|  Lab_TT436_fix  &  Lab_TT436_fix  ||
OUTPUT:	 Specimens_w_PCR                      |+|  COVID_Sequence                   ==  COVID.CEDRS_Sequence
**********************************************************************************************************/

/*-----------------------------------------------------------------------------------------------------*
 | Steps to create final dataset:
 | 1. Merge Lab_TT229_fix (PCR LabTest data)  AND  Specimens_read (Specimen data)
 |    --> Specimens_w_PCR
 | 2. Merge Lab_TT436_fix (Variant of Concern result)  AND  Lab_TT437_fix (Variant type result)
 |    --> COVID_Sequence
 | 3. Split Specimens_w_PCR into three separate datasets
 |    --> SwP1: only 1 record per Specimen and CollectionDate is NOT missing
 |    --> SwP1: only 1 collection date per Specimen and CollectionDate is NOT missing
 |    --> SwP1: everything else, e.g. CollectionDate IS missing
 | 4. Merge COVID.CEDRS_view_fix (CEDRS data)  AND  SwP1 (Specimens with PCR tests-Part 1)
 |    --> CEDRS_PCR1
 | 5. Merge CEDRS_PCR1  AND SwP2
 |    --> CEDRS_PCR2
 | 6. SKIP THIS STEP FOR NOW  (Merge CEDRS_PCR2  AND SwP3)
 | 7. Merge COVID sequence data with CEDRS_PCR data
 |    --> CEDRS_Sequence
 *------------------------------------------------------------------------------------------------------*/


*** STEP 1:  Merge Lab_TT229_fix (PCR LabTest data)  AND  Specimens_reduced (Specimen data) ***;
*** CREATES:  Specimens_w_PCR
***--------------------------------------------------------------------------------------***;

/*_____________________________________________________________________________________*
 | Lab_TT229_fix dataset comes from zDSI.LabTests where TestType='RT-PCR'.
 |    zDSI.LabTests was curated and cleaned to create Lab_TT229_fix.
 |    Lab_TT229_fix is merged with list of EventID's from CEDRS to create Lab_TT229_reduced.
 |    Lab_TT229_reduced is a LabTest level dataset, i.e. multiple PCR's per EventID.
 |    It is already sorted by LabSpecimenID EventID and filtered for CEDRS events.
 |
 | Specimens_read dataset comes from zDSI.Specimens.
 |    zDSI.Specimens was curated to create Specimens_read.
 |    It is a specimen level dataset. There is only one specimen per record.
 *______________________________________________________________________________________*/

   PROC contents data=Specimens_fix  varnum ;  title1 'Specimens_fix';  run;
   PROC contents data=Lab_TT229_fix  varnum ;  title1 'Lab_TT229_fix';  run;

   proc sort data= Specimens_fix
               out= Specimens_fix_sort;
      by EventID LabSpecimenID ;
   proc sort data= Lab_TT229_fix
               out= Lab_TT229_fix_sort;
      by EventID  LabSpecimenID ;

DATA Specimens_w_PCR; 
   merge Lab_TT229_fix_sort(in=pcr)  Specimens_fix_sort ;
   by EventID  LabSpecimenID ;
   if pcr=1;            * <--  KEEP only the specimen records that have had a PCR test;
run;

   PROC contents data=Specimens_w_PCR  varnum ;  title1 'Specimens_w_PCR';  run;


*** Repeat above for other molecular assays ***;
   proc sort data= Lab_TT434_fix
               out= Lab_TT434_fix_sort;
      by EventID  LabSpecimenID ;

DATA Specimens_w_OMA; 
   merge Lab_TT434_fix_sort(in=OMA)  Specimens_fix_sort ;
   by EventID  LabSpecimenID ;
   if OMA=1;            * <--  KEEP only the specimen records that have had a OMA test;
run;

   PROC contents data=Specimens_w_OMA  varnum ;  title1 'Specimens_w_OMA';  run;


*** Put them together by MERGE (not Concantenate) ***;
DATA Specimens_w_results ; 
   merge Specimens_w_OMA(in=OMA)  Specimens_w_PCR(in=PCR) ;
   by LabSpecimenID EventID;
run;
   PROC contents data=Specimens_w_results  varnum ;  title1 'Specimens_w_results';  run;


*** List of specimens with BOTH PCR and OMA ***;
DATA DupAssays(Keep= EventID LabSpecimenID TestTypeID_TT229  TestTypeID_TT434  CollectionDate); 
   merge Specimens_w_OMA(in=OMA)  Specimens_w_PCR(in=PCR) ;
   by LabSpecimenID EventID;
   if OMA=1 AND PCR=1;
run;

   PROC contents data=DupAssays  varnum ;  title1 'DupAssays';  run;
   PROC print data= DupAssays;  
      id EventID; 
      var LabSpecimenID CollectionDate TestTypeID_TT229 TestTypeID_TT434 ;
   title1 'data from CEDRS66.zDSI_Specimens'; 
   title2 'LSI with BOTH PCR and OMA'; 
run;



*** STEP 2:  Merge COVID sequencing LabTests data  ***;
*** CREATES:  COVID_Sequence
***------------------------------------------------***;

DATA COVID_Sequence ; 
   merge Lab_TT437_fix(in=TT437)  Lab_TT436_fix;
   by LabSpecimenID EventID;

   if TT437;
run;

   PROC contents data=COVID_Sequence  varnum ;  title1 'COVID_Sequence';  run;





*** STEP 2b:  Merge COVID sequencing LabTests data - ADD TestType=434  ***;
*** CREATES:  COVID_Sequence2 (adds "Other Molecular Assay" specimens  ***;
***--------------------------------------------------------------------***;

DATA COVID_Sequence2 ; 
   merge Lab_TT434_fix  COVID_Sequence;
   by LabSpecimenID EventID;

run;

   PROC contents data=COVID_Sequence2  varnum ;  title1 'COVID_Sequence2';  run;






*** STEP 3:  Split Specimens_w_PCR into three separate datasets   ***;
*** CREATES:  SwP1, SwP2, SwP3
***---------------------------------------------------------------***;

**  Sort Specimens_w_PCR dataset by EventID  **;
   proc sort data=Specimens_w_PCR
               out=Specimens_w_PCR_sort ;
      by EventID  CollectionDate ;
run;

**  Split Specimens_w_PCR into three separate datasets  **;
DATA SwP1  SwP2  SwP3 ; set Specimens_w_PCR_sort;
   by EventID  CollectionDate ;

* 1) SwP1 has only 1 record per Specimen and CollectionDate is NOT missing *;
   if (first.EventID=1 AND last.EventID=1)  AND  (CollectionDate ne .) then output SwP1 ;
* 2) SwP2 has only 1 collection date per Specimen and CollectionDate is NOT missing *;
   else if (first.CollectionDate=1 AND last.CollectionDate=1) AND  (CollectionDate ne .) then output SwP2 ;
* 3) SwP3 is everything else, e.g. CollectionDate IS missing *;
   else output SwP3 ;
run;

/*proc print data=swp1; var EventID  LabSpecimenID CollectionDate   ;  run; */


*** STEP 4:  Part 1 of joining PCR test data with CEDRS
***   Merge COVID.CEDRS_view_fix (CEDRS data)  AND  SwP1 (Specimens with PCR tests-Part 1)  ***;
*** CREATES:  CEDRS_PCR1
***------------------------------------------------------------------------------------------------***;

**  Sort CEDRS_fix dataset by EventID  **;
   proc sort data= COVID.CEDRS_view_fix
               out= CEDRS_sort;
      by EventID CollectionDate ;
run;

**  First merge:  CEDRS_fix with SwP1  **;
DATA CEDRS_PCR1;
   merge SwP1  CEDRS_sort(in=c) ;
   by EventID ;

   if c;
run;
/*   PROC contents data= CEDRS_PCR1  varnum  ; title1 'CEDRS_PCR1'; run;*/



*** STEP 5:  Part 2 of joining PCR test data with CEDRS  ***;
***   Merge CEDRS_PCR1  AND  SwP2 (Specimens with PCR tests-Part 2)  ***;
*** CREATES:  CEDRS_PCR2
***-----------------------------------------------------------------***;

**  Sort Specimens_w_PCR dataset by EventID  **;
   proc sort data=CEDRS_PCR1
               out=CEDRS_PCR1_sort ;
      by EventID  CollectionDate ;
run;
   proc sort data=SwP2
               out=SwP2_sort ;
      by EventID  CollectionDate ;
run;


**  Second merge:  CEDRS_PCR1 with SwP2  **;
DATA CEDRS_PCR2 ;
   merge SwP2_sort  CEDRS_PCR1_sort(in=cp) ;
   by EventID CollectionDate;

   if cp;
run;
/*   PROC contents data= CEDRS_PCR2  varnum  ; title1 'CEDRS_PCR2'; run;*/



*** STEP 6:  Part 2 of joining PCR test data with CEDRS
***   Merge CEDRS_PCR2  AND  SwP3 (Specimens with PCR tests-Part 3)  ***;
*** CREATES:  CEDRS_PCR
***-----------------------------------------------------------------***;


   /** -->  NOTE:  SAVE THIS FOR LATER. IGNORE FOR NOW  <-- ** 
    **______________________________________________________**/


** explore records that did NOT match **;
/*proc print data= CEDRS_PCR2;  where PCRds=1;  run;*/
/*proc print data= NOMATCH2; run;*/



*** STEP 7:  Merge COVID sequence data with CEDRS_PCR data  ***;
*** CREATES:  COVID.CEDRS_Sequence
***---------------------------------------------------------***;

**  Sort COVID_Sequence dataset by EventID and LabSpecimenID  **;
   proc sort data= COVID_Sequence2
               out= COVID_Sequence_sort;
      by EventID LabSpecimenID ;
run;

**  Sort CEDRS_PCR2 dataset by EventID and LabSpecimenID  **;
   proc sort data= CEDRS_PCR2
               out= CEDRS_PCR2_sort;
      by EventID LabSpecimenID ;
run;


Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

**  Merge COVID_Sequence and  CEDRS_PCR2 to create CEDRS_Sequence  **;
DATA COVID.CEDRS_Sequence;
   merge COVID_Sequence_sort  CEDRS_PCR2_sort(in=pcr) ;
   by EventID LabSpecimenID;

   if pcr;
run;
   PROC contents data= COVID.CEDRS_Sequence  varnum  ; title1 'COVID.CEDRS_Sequence'; run;
