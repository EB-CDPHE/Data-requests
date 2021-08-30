/**********************************************************************************************
PROGRAM: Fix.LabTests_TTALL
AUTHOR:  Eric Bush
CREATED:	August 26, 2021
MODIFIED: 
PURPOSE:	Make data edits to Lab_TT437_read per edit checks in CHECK.LabTests_TT437.sas
INPUT:	      Lab_TT437_fix  Lab_TT229_fix  Lab_TT436_fix
OUTPUT:	COVID.Lab_TTall_fix
***********************************************************************************************/

** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=Lab_TT437_fix varnum;  title1 'Lab_TT437_fix';  run;
   PROC contents data=Lab_TT229_fix varnum;  title1 'Lab_TT229_fix';  run;
   PROC contents data=Lab_TT436_fix varnum;  title1 'Lab_TT436_fix';  run;

DATA Lab_TTall_fix ; 
   merge Lab_TT437_fix(in=TT437)  Lab_TT229_fix  Lab_TT436_fix;
   by LabSpecimenID EventID;

   if TT437;
run;


**  STEP X:  Contents of new dataset with edits  **;
   PROC contents data=Lab_TTall_fix  varnum ;  title1 'Lab_TTall_fix';  run;


   PROC freq data= Lab_TTall_fix;
/*      tables ResultID_TT229   ;*/
/*      tables ResultText_TT229   ;*/
      tables QuantitativeResult_TT229   ;

run;

   PROC means data=Lab_TTall_fix   n nmiss;
   var ResultID;
   run;

proc freq data=Lab_TTall_fix ;
tables Variant_Type;
run;
