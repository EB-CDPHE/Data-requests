/**********************************************************************************************
PROGRAM:  Fix.LabTests_TT229
AUTHOR:   Eric Bush
CREATED:	 August 26, 2021
MODIFIED: 090121 
PURPOSE:	 Make data edits to Lab_TT229_read per edit checks in CHECK.LabTests_TT229.sas
INPUT:	      Lab_TT229_read 
OUTPUT:	      Lab_TT229_fix
***********************************************************************************************/

/*---------------------------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 | 1. De-duplicate records with two LabTest results per Specimen that have identical values in FOUR variables
 | 2. De-duplicate records with two LabTest results per Specimen that have identical values in THREE variables
 | 3. De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables
 |    AND ResultDate = missing.
 | 4. De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables
 |    AND ResultDate ^= missing.
 | 5. De-duplicate records with two LabTest results per Specimen that have identical values in ONE variable
 |    AND ResultDate = missing.
 | 6. De-duplicate records with two LabTest results per Specimen that have identical values in ONE variable
 |    AND ResultDate ^= missing.
 | 7. a) DROP extraneous variables (TestBrandID  TestBrand  LegacyTestID  CreatedByID)
 | 7. b) Delete duplicate records that are irrelevant, i.e. NO sequence results 
 | 7. c) RENAME variables to keep when merging 
 | 7. d) DROP variables not needed for merging 
 | 8. SORT fixed data for merging
 | 9. Contents of new dataset with edits
 *---------------------------------------------------------------------------------------------------------------*/

** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

title;
   PROC contents data=Lab_TT229_read varnum;  title1 'Lab_TT229_read';  run;


** STEP 1:  De-duplicate records with two LabTest results per Specimen that have identical values in FOUR variables **;
   proc sort data= Lab_TT229_read  
              out= TT229_DeDup4  NODUPKEY ;  
      by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
run;


** STEP 2:  De-duplicate records with two LabTest results per Specimen that have identical values in THREE variables **;
** Keep record with most recent CreateDate **;
   proc sort data= TT229_DeDup4  
              out= TT229_DeDup3  NODUPKEY ;  
      by LabSpecimenID  ResultID  ResultDate    ; 
run;


** STEP 3:  De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables  **;
**          AND ResultDate = .  **;
DATA TT229_DeDup2a ;   
   set TT229_DeDup3;
   by LabSpecimenID ResultID;
* Delete duplicate record where ResultDate = missing *;
   if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID ne last.ResultID)  
    AND ResultDate= . then delete ;
run;


** STEP 4:  De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables  **;
**          AND ResultDate is NOT missing.  **;
** Keep record with the earlier ResultDate  **;
   proc sort data= TT229_DeDup2a  
              out= TT229_DeDup2  NODUPKEY ;  
      by LabSpecimenID  ResultID    ; 
run;


** STEP 5:  De-duplicate records with two LabTest results per Specimen that have identical values in ONE variable  **;
**          AND ResultDate = .  **;
DATA TT229_DeDup1a ;   
   set TT229_DeDup2;
   by LabSpecimenID ResultID;
* Delete duplicate record where ResultDate = missing *;
   if (first.LabSpecimenID ne last.LabSpecimenID)  AND ResultDate= . then delete ;
run;


** STEP 6:  De-duplicate records with two LabTest results per Specimen that have identical values in ONE variable  **;
**          AND ResultDate is NOT missing.  **;
** Keep record with the earlier ResultDate  **;
   proc sort data= TT229_DeDup1a  
              out= TT229_DeDup1  NODUPKEY ;  
      by LabSpecimenID   ; 
run;


** STEP 7:  Fix data errors per findings in Check.LabTests_TT437.sas program  **;
DATA Lab_TT229_temp ;   set TT229_DeDup1 (DROP=  TestBrandID  TestBrand  LegacyTestID  CreatedByID)  ;

* Delete duplicate records that are irrelevant, i.e. do NOT have corresponding sequence results *;
   where LabSpecimenID ^in (406724, 446580, 540252, 576509, 851118, 871502, 897632, 909746, 
                            1057570, 1097798, 1098131, 1119791, 1344237, 1536073, 1725558, 
                            1735642, 1798732, 1925013, 2005303, 2362747, 2376934) ;

* RENAME variables to keep when merging with Lab_TT437_fix  *;
   RENAME   TestTypeID         = TestTypeID_TT229
            TestType           = TestType_TT229
            ResultText         = ResultText_TT229
            QuantitativeResult = QuantitativeResult_TT229
            ReferenceRange     = ReferenceRange_TT229
            ResultID           = ResultID_TT229
            ResultDate         = ResultDate_TT229
            CreateDate         = CreateDate_TT229
            UpdateDate         = UpdateDate_TT229
       ;

* DROP variables not needed for merging  *;
   DROP CreateBy  UpdatedBy  LabID  ELRID  CreateByID  ;

run;


**  STEP 8:  SORT fixed data for merging  **;
   PROC sort data= Lab_TT229_temp
               out= Lab_TT229_fix;
      by LabSpecimenID EventID;
run;

** STEP 9:  Contents of new dataset with edits **;
   PROC contents data=Lab_TT229_fix  varnum ;  title1 'Lab_TT229_fix';  run;




*** Post Edit Checks ***;
***------------------***;

**  Examine records with duplicate LabSpecimenID's  **;

   PROC freq data = Lab_TT229_fix  noprint;
      tables  LabSpecimenID / out=Lab_TT229fix_Count ;
   PROC freq data = Lab_TT229fix_Count;
      tables COUNT;
run;


   proc sort data= Lab_TT229_fix  
              out= TT229_Spec_fix ;  
      by LabSpecimenID  ResultID_TT229  ResultDate_TT229  descending CreateDate_TT229  ; 
run;

** Calculate number of variables with identical values for Dups. Creates NumDupKey **;
DATA Two_TT229_Spec_fix ;  set TT229_Spec_fix ;
   by LabSpecimenID  ResultID_TT229  ResultDate_TT229  descending CreateDate_TT229  ; 
   where LabSpecimenID ^in (406724, 446580, 540252, 576509, 851118, 871502, 897632, 909746, 
                            1057570, 1097798, 1098131, 1119791, 1344237, 1536073, 1725558, 
                            1735642, 1798732, 1925013, 2005303, 2362747, 2376934) ;

   * duplicate on all 4 variables;
        if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID_TT229 ne last.ResultID_TT229)  AND  
           (first.ResultDate_TT229 ne last.ResultDate_TT229) AND (first.CreateDate_TT229 ne last.CreateDate_TT229)  then NumDupKeys=4;  
   * duplicate on 3 variables;
   else if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID_TT229 ne last.ResultID_TT229)  AND  
           (first.ResultDate_TT229 ne last.ResultDate_TT229) then NumDupKeys=3;
   * duplicate on 2 variables;
   else if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID_TT229 ne last.ResultID_TT229)  then NumDupKeys=2;
   * duplicate on 1 variable only;
   else if (first.LabSpecimenID ne last.LabSpecimenID)  then NumDupKeys=1;
run;


**  Frequency of duplicates by the number of variables that are identical for the two results  **;
   PROC freq data= Two_TT229_Spec_fix; 
      tables NumDupKeys; 
run;

**  Print records with duplicate LabTest results per Specimen  **;
**  that have only ONE variable that is identical between the two records **;
   PROC print data= Two_TT229_Spec_fix; 
      where NumDupKeys=1;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID_TT229  ResultText_TT229  ResultDate_TT229 CreateDate_TT229  NumDupKeys ;
      format  ResultText_TT229 $10. ;
   title1 "Source data = Two_TT229_Spec_fix";
   title2 'NumDupKeys=1';
run;
