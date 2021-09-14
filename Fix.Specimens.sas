/**********************************************************************************************
PROGRAM:  Fix.Specimens.sas
AUTHOR:   Eric Bush
CREATED:	 September 14, 2021
MODIFIED:  
PURPOSE:	 Make data edits to Specimens per edit checks in CHECK.Specimens.sas
INPUT:	      Specimens_reduced 
OUTPUT:	      Specimens_fix
***********************************************************************************************/


** STEP 1:  Fix data errors per findings in Check.LabTests_TT437.sas program  **;
DATA Specimens_temp ;   set Specimens_reduced  ;

   DROP  TestBrandID  TestBrand  LegacyTestID  CreatedByID
         CreateBy  UpdatedBy  LabID  ELRID  CreateByID  ;

run;


**  STEP 2:  SORT fixed data for merging  **;
   PROC sort data= Specimens_temp
               out= Specimens_fix;
      by LabSpecimenID EventID;
run;

** STEP 3:  Contents of new dataset with edits **;
   PROC contents data=Specimens_fix  varnum ;  title1 'Specimens_fix';  run;








