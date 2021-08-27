/**********************************************************************************************
PROGRAM: Fix.LabTests_TT437
AUTHOR:  Eric Bush
CREATED:	August 26, 2021
MODIFIED: 
PURPOSE:	Make data edits to Lab_TT437_read per edit checks in CHECK.LabTests_TT437.sas
INPUT:	      Lab_TT437_read 
OUTPUT:	      Lab_TT437_fix
***********************************************************************************************/

/*------------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 | 1. De-dup records with two Test results per Specimen with identical values in FOUR variables
 | 2. De-dup records with two Test results per Specimen with identical values in THREE variables 
 | 3. Delete duplicate record where ResultDate = missing (dups with identical values in TWO vars)
 | 4. Delete duplicate records with different values for all variables (except LabSpecimenID)
 | 5. Re-format ResultText field: i.e. extract lineage name and ignore descriptive text
 *------------------------------------------------------------------------------------------------*/

** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=Lab_TT437_read varnum;  title1 'Lab_TT437_read';  run;


** De-DUP needs to occur in series (not in parallel) **;
**---------------------------------------------------**;

** STEP 1:  De-duplicate records with two LabTest results per Specimen that have identical values in FOUR variables **;
   proc sort data= Lab_TT437_read  
              out= TT437_DeDup4  NODUPKEY ;  
      by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
run;

** STEP 2:  De-duplicate records with two LabTest results per Specimen that have identical values in THREE variables **;
** Keep record with most recent CreateDate **;
   proc sort data= TT437_DeDup4  
              out= TT437_DeDup3  NODUPKEY ;  
      by LabSpecimenID  ResultID  ResultDate    ; 
run;

** STEP 3:  Fix data errors per findings in Check.LabTests_TT437.sas program  **;
DATA Lab_TT437_temp ;   
   set TT437_DeDup3 (DROP=  TestBrandID  TestBrand  LegacyTestID  CreatedByID) ;
   by LabSpecimenID ; 

* Delete duplicate record where ResultDate = missing *;
   if LabSpecimenID in (1471200, 1605796) AND ResultDate= . then delete ;

* Delete duplicate records with different values for all variables (except LabSpecimenID) *;
   if LabSpecimenID in (1346213) AND ResultID= 1062 then delete ;
   if LabSpecimenID in (1582692) AND ResultID= 1076 then delete ;

* Delete duplicate records with different values for all variables (except LabSpecimenID) *;
* AND have a ResultID = (1069 or 1070) *;
   if (first.LabSpecimenID ne last.LabSpecimenID)  AND  ResultID in (1067, 1068, 1069, 1070) then delete;

* Re-format ResultText field: i.e. extract lineage name and ignore descriptive text *;
   Variant_Type =  scan(ResultText,1,'-');     ;
   Label Variant_Type = "ResultText abbreviated " ;
run;


**  STEP 4:  SORT fixed data for merging  **;
   PROC sort data= Lab_TT437_temp
               out= Lab_TT437_fix;
      by LabSpecimenID EventID;
run;


**  STEP 5:  Contents of new dataset with edits  **;
   PROC contents data=Lab_TT437_fix  varnum ;  title1 'Lab_TT437_fix';  run;


