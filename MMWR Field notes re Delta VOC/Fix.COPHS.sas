/**********************************************************************************************
PROGRAM: Fix.COPHS
AUTHOR:  Eric Bush
CREATED:	July 5, 2021
MODIFIED:	
PURPOSE:	Make edits to COPHS dataset
INPUT:	COVID.COPHS
OUTPUT:	COVID.COPHS_fix
***********************************************************************************************/


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COVID.COPHS varnum; run;

/*--------------------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 |  1. Remove dup records by keeping record with latest ResultDate but also keep earliest create date
 |  2. Create new variables:
 |    a) County variable from County_Assigned that only includes county name (not ", CO" too)
 |    b) Age_Years by converts other age types (i.e. weeks, months) to years.
 *--------------------------------------------------------------------------------------------------------*/


DATA COVID.COPHS_fix;  set COVID.COPHS;

   * from Check.COPHS program ;
   if MR_Number = 'M1373870' and Facility_Name = 'West Pines Hospital' then delete;
   if MR_Number = 'M1535914' and Hosp_Admission='08NOV20'd and Facility_Name = 'West Pines Hospital' then delete;

   if upcase(County_of_Residence) = 'GRAND' and Zip_Code in (84515, 84532, 84540) then delete;

run;



** 3. Contents of new dataset with edits **;
   PROC contents data= COVID.COPHS_fix  varnum ;  run;




