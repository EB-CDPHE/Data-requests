/**********************************************************************************************
PROGRAM: Fix.LabTests_TT437
AUTHOR:  Eric Bush
CREATED:	August 26, 2021
MODIFIED: 
PURPOSE:	Make data edits to Lab_TT437_read per edit checks in CHECK.LabTests_TT437.sas
INPUT:	      Lab_TT437_read 
OUTPUT:	      Lab_TT437_fix
***********************************************************************************************/

/*---------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 |  1. Convert Age for all Age_Types to age in years. Creates new variable: Age_in_Years  
 *---------------------------------------------------------------------------------------------*/

** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=Lab_TT437_read varnum;  title1 'Lab_TT437_read';  run;


**  Fix data errors per findings in Check.LabTests_TT437.sas program  **;
DATA Lab_TT437_fix ;   
   set Lab_TT437_read (DROP=  TestBrandID  TestBrand  LegacyTestID  CreatedByID) ;

* Re-format ResultText field: i.e. extract lineage name and ignore descriptive text *;
   Variant_Type =  scan(ResultText,1,'-');     ;


run;


** 2. Contents of new dataset with edits **;
/*   PROC contents data=Lab_TT437_fix  varnum ;  title1 'Lab_TT437_fix';  run;*/

