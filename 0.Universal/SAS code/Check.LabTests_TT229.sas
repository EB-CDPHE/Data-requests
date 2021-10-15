/**********************************************************************************************
PROGRAM:  Check.LabTests_TT229
AUTHOR:   Eric Bush
CREATED:  August 27, 2021
MODIFIED: 091121: redirect data checks to Lab_TT229_reduced
PURPOSE:	 After a SQL data table has been read using Access.LabTests_TT229, 
            this program can be used to explore the SAS dataset.
INPUT:	 Lab_TT229_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

%Let TT229dsn = Lab_TT229_reduced ;

options pageno=1;
   PROC contents data=Lab_TT229_reduced  varnum ;  title1 'Lab_TT229_reduced';  run;

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
 | CreateDbyID only has 3500 responses, most are missing.
 | ** DO NOT USE CreateDbyID
 *_______________________________________________________________________________*/


***  2. Evaluate "ResultID" and "ResultText" variables  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT229dsn  ;
      tables ResultID * ResultText /list missing missprint; 
/*      tables QuantitativeResult ; */
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

options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;
   PROC print data = &TT229dsn ;
      where ResultID = .  AND  QuantitativeResult ne '';
      id LabSpecimenID;
      var EventiD CreateDate  ResultDate  UpdateDate  ResultID QuantitativeResult ReferenceRange   ;
      format QuantitativeResult $40.  ReferenceRange $20.  ;
run;
/*_________________________________________________________________________________________________*
 |FIX (per Quantitative Result field):
 | LSI=1344495 (EventID=1002427): ResultID=1, ResultText='Positive'
 | LSI=1605633 (EventID=1085549): ResultID=1, ResultText='Positive'
 | LSI=1627961 (EventID=1091908): ResultID=1, ResultText='Positive'
 | LSI=1680801 (EventID=1110152): ResultID=1, ResultText='Positive'
 | LSI=2038648 (EventID=1206561): ResultID=1, ResultText='Positive'
 | LSI=579427 (EventID=544660): ResultID=1, ResultText='Positive'
 | LSI=617879 (EventID=572526): ResultID=4, ResultText='Indeterminate'
 | LSI=638528 (EventID=579672): ResultID=9, ResultText='Pending'
 | LSI=656034 (EventID=595394): ResultID=4, ResultText='Indeterminate'
 | LSI=725079 (EventID=626506): ResultID=1, ResultText='Positive'
 | LSI=777605 (EventID=634247): ResultID=2, ResultText='Negative'
 | LSI=777643 (EventID=656772): ResultID=2, ResultText='Negative'
 | LSI=809156 (EventID=699093): ResultID=1, ResultText='Positive'
 | LSI=1024782 (EventID=849329): ResultID=1, ResultText='Positive'
 | LSI=1144576 (EventID=911381): ResultID=1, ResultText='Positive'
 *___________________________________________________________________________________________________*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/
   PROC print data = &TT229dsn ;
      where ResultID = 99;*  AND  QuantitativeResult ne '';
      id LabSpecimenID;
      var EventiD CreateDate  ResultDate  UpdateDate  ResultID QuantitativeResult ReferenceRange   ;
      format QuantitativeResult $40.  ReferenceRange $20.  ;
run;


***  3. Examine records with duplicate LabSpecimenID's  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT229dsn  noprint;
      tables  LabSpecimenID / out=Lab_TT229_Count ;
   PROC freq data = Lab_TT229_Count;
      tables COUNT;
      title1 'Lab_TT229_reduced'; title2;
      label count= 'Number of PCR results per Specimen from Lab_TT229_reduced';
run;


*** 3.a) Records with duplicate LabSpecimenID that have > 2 LabTest results  ***;
***--------------------------------------------------------------------------***;

* Get LabSpecimenID for these records *;
   PROC print data=  Lab_TT229_Count; 
      where COUNT > 2 ;
      id LabSpecimenID; var COUNT;
      label COUNT = 'Number of PCR results per Specimen from Lab_TT229_reduced';
run;

* Print data from  Lab_TT229_read  for these records *;
   proc sort data= &TT229dsn  
               out= TT229_Spec ;  
      by LabSpecimenID  ResultDate  ResultID  descending CreateDate  ; 
run;

   PROC print data=  TT229_Spec; 
      where LabSpecimenID in (576509, 851118, 871502, 909746, 1057570, 1097798, 
                              1098131, 1119791, 1344237, 1725558, 1735642, 
                              1925013, 2005303, 2362747, 2399014, 2405702 ) ;
      id LabSpecimenID; by LabSpecimenID; 
      var EventID ResultID  ResultDate ResultText QuantitativeResult CreateDate    ;
      format  ResultText $10.  QuantitativeResult $20.  ;
run;

* Print data from  Lab_TT437_read  for these records *;
   PROC print data=  Lab_TT437_read; 
      where LabSpecimenID in (576509, 851118, 871502, 909746, 1057570, 1097798, 
                              1098131, 1119791, 1344237, 1725558, 1735642, 
                              1925013, 2005303, 2362747, 2399014, 2405702 ) ;
      id LabSpecimenID; by LabSpecimenID; 
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID ;
      format  ResultText $10. ;
run;

/*______________________________________________________________________________________________________________*
 |FINDINGS:
 | n=15 records that have 3 LabTest results for a given LabSpecimenID
 | n=1 record that has 5 LabTest results for a given LabSpecimenID
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
   where LabSpecimenID ^in (576509, 851118, 871502, 909746, 1057570, 1097798, 
                            1098131, 1119791, 1344237, 1725558, 1735642, 
                            1925013, 2005303, 2362747, 2399014, 2405702) ;

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
      label NumDupKeys= 'Number of duplicates with identical values for key variables';
run;


/*______________________________________________________________________________________________________________*
 |FINDINGS:
 | n=10030 records with duplicate LabSpecimenID's have identical values in FOUR vars.
 | FIX: DeDup on FOUR keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 |
 | n=10 records with duplicate LabSpecimenID's have identical values in THREE vars
 | All of these are from March-April 2020 and they differ on QuantitativeResult.  
 | CreateDate differs by a one day.
 | FIX: DeDup on THREE keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 | Previous sort should be for descending CreateDate so this de-dup will keep most recent record.
 |
 | n=4 records with duplicate LabSpecimenID's have identical values in TWO vars
 | These records have same ResultID and ResultText.
 | Both ResultDate and CreateDate differ. Keep record with first ResultDate.
 | FIX: DeDup on TWO keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 |
 | n=10 records with duplicate LabSpecimenID's have identical values in ONE var (LabSpecimenID)
 | All of these have missing results (ResultID, ResultText, ResultDate) in first record.
 | FIX: delete record with ResultID= missing and keep matching record with results.
 *_______________________________________________________________________________________________________________*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 pageno=1 ;     * Landscape pagesize settings *;
**  Print records with duplicate LabTest results per Specimen  **;
**  that have FOUR variables that are identical between the two records **;
   PROC print data= Two_TT229_Spec; 
      where NumDupKeys=4;
      id LabSpecimenID;
      *by LabSpecimenID;
      var EventID ResultID ResultText QuantitativeResult  ResultDate CreateDate  CreateByID   ;
      format  ResultID 3.   ResultText $10. QuantitativeResult $40.   CreateByID 5. ;
   title1 "Source data = &TT229dsn";
   title2 'NumDupKeys=4';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have THREE variables that are identical between the two records **;
   PROC print data= Two_TT229_Spec; 
      where NumDupKeys=3;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText QuantitativeResult ReferenceRange ResultDate CreateDate  CreateByID  NumDupKeys ;
      format  ResultID 3.   ResultText $10. QuantitativeResult $40.   CreateByID 5. ;
   title1 "Source data = &TT229dsn";
   title2 'NumDupKeys=3';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have TWO variables that are identical between the two records **;
   PROC print data= Two_TT229_Spec; 
      where NumDupKeys=2;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText QuantitativeResult ReferenceRange ResultDate CreateDate  CreateByID   ;
      format  ResultID 3.   ResultText $10. QuantitativeResult $40.   CreateByID 5. ;
   title1 "Source data = &TT229dsn";
   title2 'NumDupKeys=2';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have only ONE variable that is identical between the two records **;
   PROC print data= Two_TT229_Spec; 
      where NumDupKeys=1;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText QuantitativeResult ReferenceRange ResultDate CreateDate  CreateByID   ;
      format  ResultID 3.   ResultText $10. QuantitativeResult $40.   CreateByID 5. ;
   title1 "Source data = &TT229dsn";
   title2 'NumDupKeys=1';
run;



***  4. Evaluate date variables  ***;
***------------------------------***;

** Missing values for date variables **;
   PROC means data = &TT229dsn  n nmiss ;
      var CreateDate  ResultDate  UpdateDate ; 
run;

/*____________________________________________________________*
 |FINDINGS:
 | CreateDate has no missing values. 
 | Result date is missing for approx 2.0% of PCR results.  
 | UpdateDate exists for approx 0.25% of PCR results.
 *____________________________________________________________*/


** Invalid values (i.e. date ranges) for date variables **;
   PROC freq data = &TT229dsn  ;
      tables CreateDate  ResultDate  UpdateDate  ;
/*      format CreateDate  ResultDate  UpdateDate   WeekW11. ;*/
run;

/*_____________________________________________________________________________*
 |FINDINGS:
 | CreateDate goes from 3/5/20 to present. 
 | ResultDate goes from 2/1/1920 to several months into the future, i.e. Dec 2021
 | UpdateDate goes from 3/10/20 to present. 
 |FIX:
 | Re-do data check after merging with COVID LabTests.
 *______________________________________________________________________________*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;
   PROC print data= &TT229dsn ;
      where (. < ResultDate < '01MAR20'd) ;
      id LabSpecimenID ;
      var EventiD CreateDate  ResultDate  UpdateDate  ResultID ResultText QuantitativeResult ReferenceRange  ;
      format QuantitativeResult $40.  ReferenceRange $20.  ;
    title1 'Lab_TT229_reduced';
    title2 'ResultDate < March 1, 2020';
run;
/*_____________________________________________________________________________*
 |FIX:
 | If ResultDate between Jan 1 - March 1, 2020 then change year to 2021
 | If LSI=852489 (EventID=732059) then change year to 2020 for ResultDate
 | If LSI=852489 (EventID=732059) then change year to 2020 for ResultDate
 *______________________________________________________________________________*/
