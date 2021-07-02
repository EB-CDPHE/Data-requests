/**********************************************************************************************
PROGRAM: Fix.B6172
AUTHOR:  Eric Bush
CREATED:	June 9, 2021
MODIFIED:	
PURPOSE:	Explore created SAS dataset
INPUT:	      B6172_read
OUTPUT:	COVID.B6172_fix
***********************************************************************************************/


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COVID.B6172 varnum; run;

/*
 | Fixes made in this code:
   1. Remove dup records by keeping record with latest ResultDate 
   2. Create County variable from County_Assigned that only includes county name (not ", CO" too)
*/

** 1. FIX dups: Keep record with most recent ResultDate **;
proc sort data=COVID.B6172  out=B6172_sorted ; by ProfileID EventID ResultDate CreateDate;
Data B6172_nodup; set B6172_sorted ;
   by ProfileID EventID  ;
   if last.EventID;
run;



* 2. Edit data per findings from Check program *;
DATA COVID.B6172_fix ;  set B6172_nodup ;
   County = scan(CountyAssigned,1,',');         * <-- a) new county variable ;

run;



* 3. Contents of new dataset with edits *;
   PROC contents data= COVID.B6172_fix  varnum ;  run;



