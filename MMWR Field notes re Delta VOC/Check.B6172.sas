/**********************************************************************************************
PROGRAM:  Check.B6172
AUTHOR:		Eric Bush
CREATED:	June 9, 2021
MODIFIED:	070121:  Pull out code that fixes dataset and put into separate program
PURPOSE:	Explore created SAS dataset using various edit checks
INPUT:		B6172_read        OR     B6172_fix
OUTPUT:		printed output
***********************************************************************************************/


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=B6172_read  varnum ; run;


/*________________________________________________________________________________________________________*
 | Edits checks for READ SQL data table:
 | 1. Identify Profile IDs with duplicate records  
 | 2. Print out selected fields for ALL duplicate records (if there are LOTS of them)
 |  OR
 | 2. Print out duplicate records for each Profile ID (if there are FEW of them)
 | 3. Check County_assigned variable
 |
 | Edit checks for FIXED SAS dataset
 | 3. Check edits; run frequency of key variables
 *________________________________________________________________________________________________________*/


*** check for duplicate entries, e.g. multiple sequences per patient-event ***;
***_______________________________________________________________________***;

* 1. Identify Profile IDs with duplicate records *;
   PROC FREQ data= B6172_read noprint;  
      tables ProfileID * EventID / out=DupChk(where=(count>1));
   PROC print data=DupChk; 
      id ProfileID;
run;
/*
 | FINDINGS:
 | This seems to be a regular occurrence. There are different types of dups.
 | Some differ on ResultDate. Fix: keep record with most recent (latest) ResultDate.
 | Some with identical ResultDate differ on CreateDate. Fix: keep record with latest date.
 | Some are identical on all varibles. Fix: keep last observation.
 | Can accomplish all of these fixes but sorting by ResultDate and keeping last one.
*/


* 2. Print out selected fields for ALL duplicate records *;
   proc sort data= B6172_read  out= B6172sort ;  by ProfileID  EventID ResultDate CreateDate ;
Data DupOnly;  merge B6172sort DupChk(in=Dup) ;  
 by ProfileID  EventID ;
 if Dup;
 run;

 options ps=50 ls=150 ;     * Landscape pagesize settings *;
   PROC print data= DupOnly;
      id ProfileID ; 
      var EventID gender birthdate ResultDate CreateDate  entrymethod  resulttext quantitativeresult  ;
      format lastname $15. ;
run;

/*     OR      */

* 2. Print out duplicate records for specific Profile ID identified as having duplicate records *;
    PROC print data= B6172_read;
      where ProfileID='1658113';
      id ProfileID; 
      var EventID  lastname firstname birthdate gender disease eventstatus countyassigned entrymethod CreateDate ResultDate reporteddate age outcome testtype resulttext quantitativeresult  ;
run;
** FINDING:  the difference between the two is create date and result date variables.  Delete record with earlier result date  **;

   PROC print data= B6172_read;
      where ProfileID='1685685';
      id ProfileID; 
      var EventID  lastname firstname birthdate gender disease eventstatus countyassigned entrymethod CreateDate ResultDate reporteddate age outcome testtype resulttext quantitativeresult  ;
run;
** FINDING:  both records are completely the same  **;



* 3. Check County_Assigned variable *;
DATA B6172_Ck3; set B6172_read;
   County = scan(CountyAssigned,1,',');
   PROC freq data=B6172_Ck3; 
      tables  County * CountyAssigned /list; 
run;
/*
 | FINDINGS:
 | County_Assigned variable is in form of "County name, CO".
 | FIX: create new County variable from first 'word' of County_Assigned
*/


* 4. Check edits *;

   proc print data= COVID.B6172_fix(obs=50) ;
   id profileid ;  var gender disease eventstatus county entrymethod agetype outcome testtype resulttext eventid age birthdate reporteddate;
   format reporteddate mmddyy10.  ;
/*   tables CountyAssigned ;*/
run;

   PROC freq data=COVID.B6172_fix; 
      tables gender disease eventstatus county entrymethod agetype outcome testtype resulttext  ; 
      format ResultText $variant.   ;
run;







