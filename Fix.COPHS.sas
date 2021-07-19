/**********************************************************************************************
PROGRAM:  Fix.COPHS
AUTHOR:   Eric Bush
CREATED:	 July 19, 2021
MODIFIED: 	
PURPOSE:	 Explore created SAS dataset
INPUT:	       COPHS_read
OUTPUT:	 COVID.COPHS_fix
***********************************************************************************************/

/*----------------------------------------------------------------------*
 | Fixes made in this code:
 | 1. Remove duplicate records
 | 2. Restrict County_of_Residence = 'GRAND' to only Colorado
 | 3. Contents of final dataset
 *----------------------------------------------------------------------*/

** Contents of the input SAS dataset that was created in the Access.* program and validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COPHS_read varnum; run;


***  Make edits to CEDRS_view_read and create COVID.CEDRS_view_fix  ***;
***-----------------------------------------------------------------***;

DATA COVID.COPHS_fix;  set COPHS_read;
   Region = put(County_of_Residence, $WestSlope. );

** 1) Remove duplicate record  **;
   if MR_Number = 'M1373870' and Facility_Name = 'West Pines Hospital' then delete;
   if MR_Number = 'M1535914' and Hosp_Admission='08NOV20'd and Facility_Name = 'West Pines Hospital' then delete;

** 2) Restrict County_of_Residence = 'GRAND' to only Colorado **;
   if upcase(County_of_Residence) = 'GRAND' and Zip_Code in (84515, 84532, 84540) then delete;

run;


**  3. Contents of final SAS dataset  **;

   PROC contents data=COVID.COPHS_fix varnum; run;



*** 4.  Post-edit checks ***;
***----------------------***;


