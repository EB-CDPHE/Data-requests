/**********************************************************************************************
PROGRAM:  Fix.LabTests_TT436
AUTHOR:   Eric Bush
CREATED:	 August 26, 2021
MODIFIED: 090121
PURPOSE:	 Make data edits to Lab_TT436_read per edit checks in CHECK.LabTests_TT436.sas
INPUT:	      Lab_TT436_read 
OUTPUT:	      Lab_TT436_fix
***********************************************************************************************/

/*---------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 | 1. DROP extraneous variables (TestBrandID  TestBrand  LegacyTestID  CreatedByID)
 | 2. Delete one obs of triplicate record where ResultID = 9
 | 3. Delete duplicate records that are irrelevant, i.e. NO sequence results
 | 4. De-dup records with two Test results per Specimen with identical values in FOUR variables
 | 5. De-dup records with two Test results per Specimen with identical values in TWO variables
 | 6. For duplicate records with identical values in ONE variable, delete record where result='No'
 | 7. RENAME variables to keep when merging with Lab_TT437_fix
 | 8. DROP variables not needed for merging with Lab_TT437_fix
 | 9. SORT fixed data for merging
 *---------------------------------------------------------------------------------------------*/

** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=Lab_TT436_read varnum;  title1 'Lab_TT436_read';  run;


** STEP 1:  Fix data errors per findings in Check.LabTests_TT436.sas program  **;
DATA Lab_TT436_temp ;   
   set Lab_TT436_read (DROP=  TestBrandID  TestBrand  LegacyTestID  CreatedByID) ;

* Delete one obs of triplicate record where ResultID = 9 *;
   if LabSpecimenID in (1772736) AND ResultID=9 then delete ;

* Delete duplicate records with different values for all variables (except LabSpecimenID) *;
   if LabSpecimenID in (1527798, 1527799, 1545962, 1553079)  AND  ResultID= 1072 then delete ;

run;


** STEP 2:  De-duplicate records with two LabTest results per Specimen that have identical values in FOUR variables **;
   proc sort data= Lab_TT436_temp  
               out= TT436_DeDup4  NODUPKEY ;  
      by LabSpecimenID  ResultID  descending ResultDate  descending CreateDate  ; 
run;


** STEP 3:  De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables **;
   proc sort data= TT436_DeDup4  
               out= TT436_DeDup2  NODUPKEY ;  
      by LabSpecimenID  ResultID    ; 
run;


** STEP 4:  Fix data errors per findings in Check.LabTests_TT436.sas program  **;
DATA TT436_fix;  set TT436_DeDup2;
   by LabSpecimenID ; 

  if (LabSpecimenID= 1772736) AND (EventID= 1112136) AND (ResultID= 1071) AND CreateByID= 13508 then ResultDate='23APR21'd;

* Delete duplicate records with different values for all variables (except LabSpecimenID) *;
* AND have a ResultID = 9 or 1072 *;
   if (first.LabSpecimenID ne last.LabSpecimenID)  AND  ResultID in (9, 1072) then delete;

* RENAME variables to keep when merging with Lab_TT437_fix  *;
   RENAME   TestTypeID         = TestTypeID_TT436
            TestType           = TestType_TT436
            ResultText         = ResultText_TT436
            QuantitativeResult = QuantitativeResult_TT436
            ReferenceRange     = ReferenceRange_TT436
            ResultID           = ResultID_TT436
            ResultDate         = ResultDate_TT436
            CreateDate         = CreateDate_TT436
            UpdateDate         = UpdateDate_TT436  ;

* DROP variables not needed for merging with Lab_TT437_fix  *;
   DROP CreateBy  UpdatedBy  LabID  ELRID  CreateByID  ;

run;


**  STEP 5:  SORT fixed data for merging  **;
   PROC sort data=     TT436_fix
               out= Lab_TT436_fix;
      by LabSpecimenID  EventID;
run;


** STEP 6:  Contents of new dataset with edits **;
   PROC contents data=Lab_TT436_fix  varnum ;  title1 'Lab_TT436_fix';  run;



