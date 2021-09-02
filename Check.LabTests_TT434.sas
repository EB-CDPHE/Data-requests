/**********************************************************************************************
PROGRAM:  Check.LabTests_TT434
AUTHOR:   Eric Bush
CREATED:  September 2, 2021
MODIFIED: 
PURPOSE:	 After a SQL data table has been read using Access.LabTests_TT434, 
            this program can be used to explore the SAS dataset.
INPUT:	 Lab_TT434_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

%Let TT434dsn = Lab_TT434_read ;

options pageno=1;
   PROC contents data=Lab_TT434_read  varnum ;  title1 'Lab_TT434_read';  run;

/*------------------------------------------------------------------------------*
 | Check Lab_TT229_read data for:
 | 1. Compare "CreateBY" and "CreatedBY" variables
 | 2. Evaluate "ResultID" and "ResultText" variables
 | 3. Examine records with duplicate LabSpecimenID's
 |    a) Records with duplicate LabSpecimenID that have > 2 LabTest results 
 |    b) Records with duplicate LabSpecimenID that have 2 LabTest results
 | 4. Evaluate date variables
 *------------------------------------------------------------------------------*/


***  1. Compare "CreateBY" and "CreatedBY" variables  ***;
***---------------------------------------------------***;

   PROC means data = &TT434dsn  n nmiss ;
      var CreateBYID   CreatedBYID   ; 
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | CreateBYID has no missing responses
 | CreateDbyID only has 700 responses, most are missing.
 | ** DO NOT USE CreateDbyID
 *_______________________________________________________________________________*/


***  2. Evaluate "ResultID" and "ResultText" variables  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT434dsn  ;
      tables ResultID * ResultText /list missing missprint; 
      tables QuantitativeResult ; 
run;

/*_________________________________________________________________________________________________*
 |FINDINGS:
 | ResultID is the numeric code assigned to ResultText. 
 | ResultText holds the description of the results for "Other Molecular Assays".
 |    ResultID=1 for ResultText = 'Positive'
 |    ResultID=2 for ResultText = 'Negative'
 |    ResultID=4 for ResultText = 'Indeterminate'
 |    ResultID=9 for ResultText = 'Unknown'
 | n=28 records are missing ResultID and ResultText
 | QuantitativeResult variable is nearly useless given wide range of responses.
 *___________________________________________________________________________________________________*/


***  3. Examine records with duplicate LabSpecimenID's  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT434dsn  noprint;
      tables  LabSpecimenID / out=Lab_TT434_Count ;
   PROC freq data = Lab_TT434_Count;
      tables COUNT;
      title1 'Lab_TT434_read';
      title2 'Frequency count of LabSpecimenID';
run;


*** 3.a) Records with duplicate LabSpecimenID that have > 2 LabTest results  ***;
***--------------------------------------------------------------------------***;

* Get LabSpecimenID for these records *;
   PROC print data=  Lab_TT434_Count; 
      where COUNT > 2 ;
      id LabSpecimenID; var COUNT;
run;

* Print data from  Lab_TT434_read  for these records *;
   proc sort data= &TT434dsn  
               out= TT434_Spec ;  
      by LabSpecimenID  ResultDate  ResultID  descending CreateDate  ; 
run;

   PROC print data=  TT434_Spec; 
      where LabSpecimenID in (937046 ) ;
      id LabSpecimenID; by LabSpecimenID; 
      var EventID ResultID  ResultDate ResultText QuantitativeResult CreateDate    ;
      format  ResultText $10.  QuantitativeResult $20.  ;
run;

* Print data from  Lab_TT437_read  for these records *;
   PROC print data=  Lab_TT437_read; 
      where LabSpecimenID in (937046 ) ;
      id LabSpecimenID; by LabSpecimenID; 
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID ;
      format  ResultText $10. ;
run;

/*______________________________________________________________________________________________________________*
 |FINDINGS:
 | n=1 record that has 3 LabTest results for a given LabSpecimenID
 | NONE of these LabSpecimens have been sequenced, i.e. NONE have corresponding TestType=437.
 |FIX:  Delete this record prior to merge with Lab_TT437_fix.
 *_______________________________________________________________________________________________________________*/



*** 3.b) Records with duplicate LabSpecimenID that have 2 LabTest results  ***;
***-----------------------------------------------------------------------------***;

   proc sort data= &TT434dsn  
              out= TT434_Spec ;  
      by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
run;

** Calculate number of variables with identical values for Dups. Creates NumDupKey **;
DATA Two_TT434_Spec ;  set TT434_Spec ;
   by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
      where LabSpecimenID in (937046 ) ;

   * duplicate on all 4 variables;
        if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID ne last.ResultID)  AND  
           (first.ResultDate ne last.ResultDate) AND (first.CreateDate ne last.CreateDate)  then NumDupKeys=4;  
   * duplicate on 3 variables;
   else if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID ne last.ResultID)  AND  
           (first.ResultDate ne last.ResultDate) then NumDupKeys=3;
   * duplicate on 2 variables;
   else if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID ne last.ResultID)  then NumDupKeys=2;
   * duplicate on 1 variable only;
   else if (first.LabSpecimenID ne last.LabSpecimenID)  then NumDupKeys=1;

run;


**  Frequency of duplicates by the number of variables that are identical for the two results  **;
   PROC freq data= Two_TT434_Spec; 
      tables NumDupKeys; 
run;


/*______________________________________________________________________________________________________________*
 |FINDINGS:
 | n=9891 records with duplicate LabSpecimenID's have identical values in FOUR vars
 | FIX: DeDup on FOUR keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 |
 | n=20 records with duplicate LabSpecimenID's have identical values in THREE vars
 | ?All but two of these pairs have ResultID in (1067, 1070). Were they re-sequenced?
 | ?FIX: DeDup on THREE keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 | ?Previous sort should be for descending CreateDate so this de-dup will keep most recent record.
 |
 | n=147 records with duplicate LabSpecimenID's have identical values in TWO vars
 | ?These records have same ResultID and ResultText. The ResultDate differs because one value is missing.
 | ?FIX: Delete record with missing ResultDate.
 |
 | n=82 records with duplicate LabSpecimenID's have identical values in ONE var (LabSpecimenID)
 | ?All but two of these pairs had ResultID= 1069 or 1070 for one record in duplicate pair.
 | ?The two exceptions had one record with result text that contained "LIKE".
 | ?FIX: delete record with ResultID= 1069 or 1070 and keep matching record with other ResultID.
 | ?FIX: delete record with result text that contains "LIKE".
 *_______________________________________________________________________________________________________________*/


**  Print records with duplicate LabTest results per Specimen  **;
**  that have FOUR variables that are identical between the two records **;
   PROC print data= Two_TT434_Spec; 
      where NumDupKeys=4;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT434dsn";
   title2 'NumDupKeys=4';
run;



***  4. Evaluate date variables  ***;
***------------------------------***;

** Missing values for date variables **;
   PROC means data = &TT434dsn  n nmiss ;
      var ResultDate  CreateDate  UpdateDate ; 
run;

/*____________________________________________________________*
 |FINDINGS:
 | CreateDate has no missing values. 
 | UpdateDate exists for approx 0.8% of PCR results.
 | Result date is missing for approx 2.0% of PCR results.  
 *____________________________________________________________*/


** Invalid values (i.e. date ranges) for date variables **;
   PROC freq data = &TT434dsn  ;
      tables ResultDate  CreateDate  UpdateDate  ;
      format ResultDate  CreateDate  UpdateDate   WeekW11. ;
run;

/*_____________________________________________________________________________*
 |FINDINGS:
 | All date values are from much earlier time period than COVID, e.g. 1982.
 | ResultDate has values several months into the future, e.g. week 48, 2021
 | CreateDate goes from 2020 to present. 
 | UpdateDate goes from 2020 to present. 
 |FIX:
 | Re-do data check after merging with COVID LabTests.
 *______________________________________________________________________________*/


