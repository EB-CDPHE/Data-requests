/**********************************************************************************************
PROGRAM:  Fix.LabTests_TT434
AUTHOR:   Eric Bush
CREATED:	 September 2, 2021
MODIFIED: 
PURPOSE:	 Make data edits to Lab_TT434_read per edit checks in CHECK.LabTests_TT434.sas
INPUT:	      Lab_TT434_read 
OUTPUT:	      Lab_TT434_fix
***********************************************************************************************/

/*---------------------------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 | 1. De-dup records with two Test results per Specimen with identical values in FOUR variables
 | 2. De-duplicate records with two LabTest results per Specimen that have identical values in THREE variables
 | 3. De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables
 |    AND ResultDate = missing.
 | 3. DROP extraneous variables (TestBrandID  TestBrand  LegacyTestID  CreatedByID)
 | 4. De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables
 |    AND ResultDate ^= missing.
 | 5. a) De-duplicate records with two LabTest results per Specimen that have identical values in ONE variable
 |       AND ResultID = missing.
 | 5. b) RENAME variables to keep when merging with Lab_TT437_fix
 | 5. c) DROP variables not needed for merging with Lab_TT437_fix
 | 6. SORT fixed data for merging
 | 7. Contents of new dataset with edits
 *---------------------------------------------------------------------------------------------------------------*/

** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=Lab_TT434_read varnum;  title1 'Lab_TT434_read';  run;


** STEP 1:  De-duplicate records with two LabTest results per Specimen that have identical values in FOUR variables **;
   proc sort data= Lab_TT434_read  
              out= TT434_DeDup4  NODUPKEY ;  
      by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
run;


** STEP 2:  De-duplicate records with two LabTest results per Specimen that have identical values in THREE variables **;
** Keep record with most recent (latest) CreateDate **;
   proc sort data= TT434_DeDup4  
              out= TT434_DeDup3  NODUPKEY ;  
      by LabSpecimenID  ResultID  ResultDate    ; 
run;


** STEP 3:  De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables  **;
**          AND ResultDate = .  **;
DATA TT434_DeDup2a ;   
   set TT434_DeDup3(DROP=  TestBrandID  TestBrand  LegacyTestID  CreatedByID);
   by LabSpecimenID ResultID;
* Delete duplicate record where ResultDate = missing *;
   if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID ne last.ResultID)  
    AND ResultDate= . then delete ;
run;


** STEP 4:  De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables  **;
**          AND ResultDate is NOT missing.  **;
** Keep record with the earlier ResultDate  **;
   proc sort data= TT434_DeDup2a  
              out= TT434_DeDup2  NODUPKEY ;  
      by LabSpecimenID  ResultID    ; 
run;


** STEP 5:  Fix data errors per findings in Check.LabTests_TT434.sas program  **;
DATA TT434_fix;  set TT434_DeDup2;
   by LabSpecimenID ; 

* Delete duplicate record where ResultDate = missing *;
   if (first.LabSpecimenID ne last.LabSpecimenID)  AND ResultID= . then delete ;

* RENAME variables to keep when merging with Lab_TT437_fix  *;
   RENAME   TestTypeID         = TestTypeID_TT434
            TestType           = TestType_TT434
            ResultText         = ResultText_TT434
            QuantitativeResult = QuantitativeResult_TT434
            ReferenceRange     = ReferenceRange_TT434
            ResultID           = ResultID_TT434
            ResultDate         = ResultDate_TT434
            CreateDate         = CreateDate_TT434
            UpdateDate         = UpdateDate_TT434  ;

* DROP variables not needed for merging with Lab_TT437_fix  *;
   DROP CreateBy  UpdatedBy  LabID  ELRID  CreateByID  ;

run;


**  STEP 6:  SORT fixed data for merging  **;
   PROC sort data=     TT434_fix
               out= Lab_TT434_fix;
      by LabSpecimenID  EventID;
run;


** STEP 7:  Contents of new dataset with edits **;
   PROC contents data=Lab_TT434_fix  varnum ;  title1 'Lab_TT434_fix';  run;




