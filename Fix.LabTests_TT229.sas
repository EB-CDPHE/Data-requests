/**********************************************************************************************
PROGRAM: Fix.LabTests_TT229
AUTHOR:  Eric Bush
CREATED:	August 26, 2021
MODIFIED: 
PURPOSE:	Make data edits to Lab_TT229_read per edit checks in CHECK.LabTests_TT229.sas
INPUT:	      Lab_TT229_read 
OUTPUT:	      Lab_TT229_fix
***********************************************************************************************/

/*---------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 | 1. DROP extraneous variables (TestBrandID  TestBrand  LegacyTestID  CreatedByID)
 | 2. Delete duplicate records that are irrelevant, i.e. NO sequence results 
 | 3. RENAME variables to keep when merging with Lab_TT437_fix
 | 4. DROP variables not needed for merging with Lab_TT437_fix
 | 5. SORT fixed data for merging
 *---------------------------------------------------------------------------------------------*/

** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=Lab_TT229_read varnum;  title1 'Lab_TT229_read';  run;

** STEP 1:  Fix data errors per findings in Check.LabTests_TT437.sas program  **;
DATA Lab_TT229_temp ;   
   set Lab_TT229_read (DROP=  TestBrandID  TestBrand  LegacyTestID  CreatedByID) ;

* Delete duplicate records that are irrelevant, i.e. do NOT have corresponding sequence results *;
   where LabSpecimenID ^in (406724, 446580, 540252, 576509, 851118, 871502, 897632, 909746, 
                            1057570, 1097798, 1098131, 1119791, 1344237, 1536073, 1725558, 
                            1735642, 1798732, 1925013, 2005303, 2362747, 2376934 ) ;

* RENAME variables to keep when merging with Lab_TT437_fix  *;
   RENAME   ResultText         = ResultText_TT229
            QuantitativeResult = QuantitativeResult_TT229
            ReferenceRange     = ReferenceRange_TT229
            ResultID           = ResultID_TT229
            ResultDate         = ResultDate_TT229
            CreateDate         = CreateDate_TT229
            UpdateDate         = UpdateDate_TT229
       ;

* DROP variables not needed for merging with Lab_TT437_fix  *;
   DROP CreateBy  UpdatedBy  LabID  ELRID  CreateByID  TestTypeID TestType  ;

run;

**  STEP 2:  SORT fixed data for merging  **;
   PROC sort data= Lab_TT229_temp
               out= Lab_TT229_fix;
      by LabSpecimenID EventID;
run;

** STEP 3:  Contents of new dataset with edits **;
   PROC contents data=Lab_TT229_fix  varnum ;  title1 'Lab_TT229_fix';  run;


