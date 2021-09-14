/**********************************************************************************************
PROGRAM: Fix.zDSI_Events
AUTHOR:  Eric Bush
CREATED:	July 15, 2021
MODIFIED: 081321: Switch from char var AgeType to numeric var AgeTypeID	
PURPOSE:	Make data edits to zDSI_Events_read per edit checks in CHECK.zDSI_Events_read.sas
INPUT:	zDSI_Events_read 
OUTPUT:	zDSI_Events_fix
***********************************************************************************************/

/*---------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 |  1. Convert Age for all Age_Types to age in years. Creates new variable: Age_in_Years  
 *---------------------------------------------------------------------------------------------*/

** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=zDSI_Events_read varnum; run;


** 1. Create Age in years variable from other Age Type records **;
DATA zDSI_Events_fix ;   set zDSI_Events_read ;
   if AgeTypeID = 4 then Age_Years = Age/365;
   if AgeTypeID = 3 then Age_Years = Age/52;
   if AgeTypeID = 2 then Age_Years = Age/12;
   if AgeTypeID = 1 then Age_Years = Age;
/*   if upcase(AgeType) = 'DAYS' then Age_Years = Age/365;*/
/*   if upcase(AgeType) = 'WEEKS'  then Age_Years = Age/52;*/
/*   if upcase(AgeType) = 'MONTHS' then Age_Years = Age/12;*/
/*   if upcase(AgeType) = 'YEARS'  then Age_Years = Age;*/
   Label Age_Years = 'Age in years';
   drop AgeTypeID  Age ;
run;


** 2. Contents of new dataset with edits **;
   PROC contents data=zDSI_Events_fix varnum; title1 'zDSI_Events_fix'; run;
