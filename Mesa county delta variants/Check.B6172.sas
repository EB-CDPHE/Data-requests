/**********************************************************************************************
PROGRAM:  Explore.B6172
AUTHOR:		Eric Bush
CREATED:	June 9, 2021
MODIFIED:	
PURPOSE:	Explore created SAS dataset
INPUT:		COVID.B6172
OUTPUT:		VOC_CO
***********************************************************************************************/


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COVID.B6172 varnum; run;


/*________________________________________________________________________________________________________*
 | Table of Contents:
 | 1. Identify Profile IDs with duplicate records  
 | 2. Print out duplicate records for each Profile ID
 | 3. Make edits to the data per findings from data checks
 | 4. Remove records that have duplicate values for ALL variables
 | --> filtered dataset (de-duplicated)
 | 5. PROC Contents of dataset with edits
 | 6. Check edits; run frequency of key variables
 *________________________________________________________________________________________________________*/


*** check for duplicate entries, e.g. multiple sequences per patient-event ***;
***_______________________________________________________________________***;

* 1. Identify Profile IDs with duplicate records *;
   PROC FREQ data= COVID.B6172 noprint;  
      tables ProfileID * EventID / out=DupChk(where= count>1);
   PROC print data=DupChk; 
      id ProfileID;
run;

* 2. Print out duplicate records for each Profile ID identified as having duplicate records *;
   PROC print data= COVID.B6172;
      where ProfileID='1650460';
      id ProfileID; 
      var EventID  lastname firstname birthdate gender disease eventstatus countyassigned entrymethod CreateDate ResultDate reporteddate age outcome testtype resulttext quantitativeresult  ;
run;
** FINDING:  the difference in the two records is in quantitativeresult.  Delete record with null result  **;

/*proc print data= COVID.B6172;*/
/*where profileid='1666508';*/
/*id profileID; */
/*var EventID  lastname firstname birthdate gender disease eventstatus countyassigned entrymethod reporteddate age outcome testtype resulttext quantitativeresult;*/
/*run;*/
** FINDING:  the difference in the two records is in resulttext.  Delete record where resulttext contains "6.1.1"  **;
** UPDATE: the dup records for this ProfileID is now resolved in source dataset ;
  
   PROC print data= COVID.B6172;
      where ProfileID='1658113';
      id ProfileID; 
      var EventID  lastname firstname birthdate gender disease eventstatus countyassigned entrymethod CreateDate ResultDate reporteddate age outcome testtype resulttext quantitativeresult  ;
run;
** FINDING:  the difference between the two is create date and result date variables.  Delete record with earlier result date  **;

   PROC print data= COVID.B6172;
      where ProfileID='1685685';
      id ProfileID; 
      var EventID  lastname firstname birthdate gender disease eventstatus countyassigned entrymethod CreateDate ResultDate reporteddate age outcome testtype resulttext quantitativeresult  ;
run;
** FINDING:  both records are completely the same  **;



*** Code to run to edit COVID.B6172 dataset to use for RFI analysis ***;
***vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv***;

* 3. Edit data per above findings *;
DATA B6172_temp ;  set COVID.B6172 ;
   County = scan(CountyAssigned,1);
   if ProfileID in ('1650460', '1658113', '1685685') then DO;
      if EventID = '1159166' and quantitativeresult='' then delete;
      if EventID = '1167191' and ResultDate = '07JUN21'd then delete;
   END;
run;

* 4. Remove records that have duplicate values for ALL variables *;
PROC sort data=B6172_temp  out=B6172_edit  NoDup ;  by _ALL_;  run;


* 5. Contents of new dataset with edits *;
   PROC contents data= B6172_edit varnum ;  run;

***^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^***;
*** Code to run to edit COVID.B6172 dataset to use for RFI analysis ***;



* 6. Check edits *;

PROC freq data=B6172_edit; tables  County * CountyAssigned /list; run;

   proc print data= B6172_edit(obs=50) ;
   id profileid ;  var gender disease eventstatus county entrymethod agetype outcome testtype resulttext eventid age birthdate reporteddate;
   format reporteddate mmddyy10.  ;
/*   tables CountyAssigned ;*/
run;

   PROC freq data=B6172_edit; 
      tables gender disease eventstatus county entrymethod agetype outcome testtype resulttext  ; 
      format ResultText $variant.   ;
run;







