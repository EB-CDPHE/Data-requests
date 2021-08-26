/**********************************************************************************************
PROGRAM: Fix.LabTests_TT437
AUTHOR:  Eric Bush
CREATED:	July 15, 2021
MODIFIED: 081321: Switch from char var AgeType to numeric var AgeTypeID	
PURPOSE:	Make data edits to zDSI_Events_read per edit checks in CHECK.zDSI_Events_read.sas
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
DATA Lab_TT437_fix ;   set Lab_TT437_read ;

   DROP  TestBrandID  TestBrand  LegacyTestID  CreatedByID   ;
run;


** 2. Contents of new dataset with edits **;
   PROC contents data=Lab_TT437_fix  varnum ;  title1 'Lab_TT437_fix';  run;
