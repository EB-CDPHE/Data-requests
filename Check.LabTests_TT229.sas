/**********************************************************************************************
PROGRAM:  Check.LabTests_TT229
AUTHOR:   Eric Bush
CREATED:  August 27, 2021
MODIFIED: 090121
PURPOSE:	 After a SQL data table has been read using Access.LabTests_TT229, 
            this program can be used to explore the SAS dataset.
INPUT:	 Lab_TT229_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

%Let TT229dsn = Lab_TT229_read ;

options pageno=1;
   PROC contents data=Lab_TT229_read  varnum ;  title1 'Lab_TT229_read';  run;

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

   PROC means data = &TT229dsn  n nmiss ;
      var CreateBYID   CreatedBYID   ; 
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | CreateBYID has no missing responses
 | CreateDbyID only has 3900 responses, most are missing.
 | ** DO NOT USE CreateDbyID
 *_______________________________________________________________________________*/


***  2. Evaluate "ResultID" and "ResultText" variables  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT229dsn  ;
      tables ResultID * ResultText /list missing missprint; 
      tables QuantitativeResult ; 
run;

/*_________________________________________________________________________________________________*
 |FINDINGS:
 | ResultID is the numeric code assigned to ResultText. 
 | ResultText holds the description of the RT_PCR result.
 |    ResultID=1 for ResultText = 'Positive'
 |    ResultID=2 for ResultText = 'Negative'
 |    ResultID=4 for ResultText = 'Indeterminate'
 |    ResultID=9 for ResultText = 'Unknown'
 |    ResultID=99 for ResultText = 'Result is Text'
 | QuantitativeResult variable is nearly useless given wide range of responses.
 *___________________________________________________________________________________________________*/


***  3. Examine records with duplicate LabSpecimenID's  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT229dsn  noprint;
      tables  LabSpecimenID / out=Lab_TT229_Count ;
   PROC freq data = Lab_TT229_Count;
      tables COUNT;
      title1 'Lab_TT229_read';
      title2 'Frequency count of LabSpecimenID';
run;


*** 3.a) Records with duplicate LabSpecimenID that have > 2 LabTest results  ***;
***--------------------------------------------------------------------------***;

* Get LabSpecimenID for these records *;
   PROC print data=  Lab_TT229_Count; 
      where COUNT > 2 ;
      id LabSpecimenID; var COUNT;
run;

* Print data from  Lab_TT229_read  for these records *;
   proc sort data= &TT229dsn  
               out= TT229_Spec ;  
      by LabSpecimenID  ResultDate  ResultID  descending CreateDate  ; 
run;

   PROC print data=  TT229_Spec; 
      where LabSpecimenID in (406724, 446580, 540252, 576509, 851118, 871502, 897632, 909746, 
                              1057570, 1097798, 1098131, 1119791, 1344237, 1536073, 1725558, 
                              1735642, 1798732, 1925013, 2005303, 2362747, 2376934 ) ;
      id LabSpecimenID; by LabSpecimenID; 
      var EventID ResultID  ResultDate ResultText QuantitativeResult CreateDate    ;
      format  ResultText $10.  QuantitativeResult $20.  ;
run;

* Print data from  Lab_TT437_read  for these records *;
   PROC print data=  TT437_Spec; 
      where LabSpecimenID in (406724, 446580, 540252, 576509, 851118, 871502, 897632, 909746, 
                              1057570, 1097798, 1098131, 1119791, 1344237, 1536073, 1725558, 
                              1735642, 1798732, 1925013, 2005303, 2362747, 2376934 ) ;
      id LabSpecimenID; by LabSpecimenID; 
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID ;
      format  ResultText $10. ;
run;

/*______________________________________________________________________________________________________________*
 |FINDINGS:
 | n=19 records that have 3 LabTest results for a given LabSpecimenID
 | n=1 record that has 7 LabTest results for a given LabSpecimenID
 | n=1 record that has 13 LabTest results for a given LabSpecimenID
 | NONE of these LabSpecimens have been sequenced, i.e. NONE have corresponding TestType=437.
 |FIX:  Delete these records prior to merge with Lab_TT437_fix.
 *_______________________________________________________________________________________________________________*/



*** 3.b) Records with duplicate LabSpecimenID that have 2 LabTest results  ***;
***-----------------------------------------------------------------------------***;

   proc sort data= &TT229dsn  
              out= TT229_Spec ;  
      by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
run;

** Calculate number of variables with identical values for Dups. Creates NumDupKey **;
DATA Two_TT229_Spec ;  set TT229_Spec ;
   by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
   where LabSpecimenID ^in (406724, 446580, 540252, 576509, 851118, 871502, 897632, 909746, 
                            1057570, 1097798, 1098131, 1119791, 1344237, 1536073, 1725558, 
                            1735642, 1798732, 1925013, 2005303, 2362747, 2376934) ;

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
   PROC freq data= Two_TT229_Spec; 
      tables NumDupKeys; 
run;


/*______________________________________________________________________________________________________________*
 |FINDINGS:
 | n=9891 records with duplicate LabSpecimenID's have identical values in FOUR vars
 | FIX: DeDup on FOUR keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 |
 | n=20 records with duplicate LabSpecimenID's have identical values in THREE vars
 | Most have CreateDate that differs by a one day. Some differ by 1 or more months.
 | FIX: DeDup on THREE keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 | Previous sort should be for descending CreateDate so this de-dup will keep most recent record.
 |
 | n=147 records with duplicate LabSpecimenID's have identical values in TWO vars
 | These records have same ResultID and ResultText. The ResultDate differs because one value is missing.
 | FIX: Delete record with missing ResultDate. OTherwise take the record with latest result date.
 |
 | n=82 records with duplicate LabSpecimenID's have identical values in ONE var (LabSpecimenID)
 | Some of these had missing results.
 | Other times the results differed, e.g. Positive result on one record and negative result on the other
 | FIX: delete record with ResultID= missing and keep matching record with other ResultID.
 | FIX: keep record with lowest value for ResultID, e.g. Positive result over the Negative result 
 *_______________________________________________________________________________________________________________*/


**  Print records with duplicate LabTest results per Specimen  **;
**  that have FOUR variables that are identical between the two records **;
/*   PROC print data= Two_TT229_Spec; */
/*      where NumDupKeys=4;*/
/*      id LabSpecimenID;*/
/*      by LabSpecimenID;*/
/*      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;*/
/*      format  ResultText $10. ;*/
/*   title1 "Source data = &TT229dsn";*/
/*   title2 'NumDupKeys=4';*/
/*run;*/


**  Print records with duplicate LabTest results per Specimen  **;
**  that have THREE variables that are identical between the two records **;
   PROC print data= Two_TT229_Spec; 
      where NumDupKeys=3;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT229dsn";
   title2 'NumDupKeys=3';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have TWO variables that are identical between the two records **;
   PROC print data= Two_TT229_Spec; 
      where NumDupKeys=2;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT229dsn";
   title2 'NumDupKeys=2';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have only ONE variable that is identical between the two records **;
   PROC print data= Two_TT229_Spec; 
      where NumDupKeys=1;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT229dsn";
   title2 'NumDupKeys=1';
run;



***  4. Evaluate date variables  ***;
***------------------------------***;

** Missing values for date variables **;
   PROC means data = &TT229dsn  n nmiss ;
      var ResultDate  CreateDate  UpdateDate ; 
run;

/*____________________________________________________________*
 |FINDINGS:
 | CreateDate has no missing values. 
 | UpdateDate exists for approx 0.3% of PCR results.
 | Result date is missing for approx 2.0% of PCR results.  
 *____________________________________________________________*/


** Invalid values (i.e. date ranges) for date variables **;
   PROC freq data = &TT229dsn  ;
      tables ResultDate  CreateDate  UpdateDate  ;
      format ResultDate  CreateDate  UpdateDate   WeekW11. ;
run;

/*_____________________________________________________________________________*
 |FINDINGS:
 | All date values are from much earlier time period than COVID, i.e. 1920.
 | ResultDate has values several months into the future, i.e. Dec 2021
 | CreateDate goes from 2013 to present. 
 | UpdateDate goes from 2017 to present. 
 |FIX:
 | Re-do data check after merging with COVID LabTests.
 *______________________________________________________________________________*/

