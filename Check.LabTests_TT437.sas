/**********************************************************************************************
PROGRAM:  Check.LabTests_TT437
AUTHOR:   Eric Bush
CREATED:  August 20, 2021
MODIFIED: 
PURPOSE:	 After a SQL data table has been read using Access.LabTests_TT437, 
            this program can be used to explore the SAS dataset.
INPUT:	 Lab_TT437_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

%Let TT437dsn = Lab_TT437_read ;

options pageno=1;
   PROC contents data=Lab_TT437_read  varnum ;  title1 'Lab_TT437_read';  run;

/*--------------------------------------------------------------------*
 | Check Lab_TT437_read data for:
 |  1. Compare "CreateBY" and "CreatedBY" variables
 |  2. Evaluate "CreateByID" and "CreateBy" variables
 |  3. Evaluate "UpdatedBy" variables
 |  4. Evaluate "TestBrandID" and "TestBrand" variables
 |  5. Explore relationship between LabID and LabSpecimenID
 |  6. Examine records with duplicate LabSpecimenID's
 |     a) Records with duplicate LabSpecimenID that have 3 or 4 LabTest results  ***;
 |     b) Records with duplicate LabSpecimenID that have 2 LabTest results
 |  7. Evaluate "ResultID" and "ResultText" variables
 |  8. Evaluate "ELRID" variable
 |  9. Evaluate date variables
 | 10. Explore relationship between CreateDate and ResultDate
 | 11. Check for results = "Specimen unsatisfactory for evaluation"
 *--------------------------------------------------------------------*/


***  1. Compare "CreateBY" and "CreatedBY" variables  ***;
***---------------------------------------------------***;

   PROC means data = &TT437dsn  n nmiss ;
      var CreateBYID   CreatedBYID   ; 
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | CreateBYID has no missing responses
 | CreateDbyID only has 1200 responses, most are missing.
 | ** DO NOT USE CreateDbyID
 *_______________________________________________________________________________*/


***  2. Evaluate "CreateByID" and "CreateBy" variables  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT437dsn  order=freq;
      tables CreateByID * CreateBy /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | CreateByID is the numeric code assigned to names
 | CreateBy holds the names.
 | Almost 90% of COVID lab test results were created by 7 people:
 |    Emily Hentz Leister (21%), Sara Kitchen (18%), Christina Goode (18%)
 |    Elizabeth Sogunle (11%), Lauren Caggiano (10%), Keelin Bettridge (5%)
 |    Breanna Kawasaki (4%)
 | n=25 different individuals have created lab tests results,
 | including "System Admin" (ID=9999)
 | n=8 individuals have created fewer than 10 lab tests results.
 *_______________________________________________________________________________*/


***  3. Evaluate "UpdatedBy" variables  ***;
***-------------------------------------***;

   PROC freq data = &TT437dsn  ;
/*      tables  UpdatedBy;*/
      tables CreateByID *  UpdatedBy /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | UpdatedBy holds the names of individuals that updated lab results.
 | UpdatedBy does NOT match (or align with) CreateByID.
 *_______________________________________________________________________________*/


***  4. Evaluate "TestBrandID" and "TestBrand" variables  ***;
***-------------------------------------------------------***;

   PROC freq data = &TT437dsn  order=freq;
      tables TestBrandID * TestBrand /list  missing missprint; 
run;

 **  Evaluate "LegacyTestID" variable  **;
   PROC means data = &TT437dsn  n nmiss ;
      var LegacyTestID   ; 
run;

/*__________________________________________________*
 |FINDINGS:
 | All values of these variables are missing.
 | DROP these three variables.
 *__________________________________________________*/


***  5. Explore relationship between LabID and LabSpecimenID  ***;
***-----------------------------------------------------------***;

  PROC means data = &TT437dsn  n nmiss ;
      var LabID  LabSpecimenID   ; 
run;

/*   PROC freq data = &TT437dsn;  tables LabID  LabSpecimenID  ;  run;*/

/*_______________________________________________________________________________________*
 |FINDINGS:
 | Records with duplicate LabSpecimenID have same EventID but different, unique LabID's
 | In other words, a LabSpecimenID can have multiple LabID's.
 *_______________________________________________________________________________________*/


***  6. Examine records with duplicate LabSpecimenID's  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT437dsn;
      tables  LabSpecimenID / out=Lab_TT437_Count ;
   PROC freq data = Lab_TT437_Count;
      tables COUNT;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | LabID:  No values are missing. This is a 7 digit ID unique for each record
 | LabSpecimenID:  No values are missing. This is a 6 or 7 digit ID. Most are unique.
 | N = 35,339 records with LabSpecimenID. Most records have only 1 LabSpecimenID.  
 | N = 35121 unique LabSpecimenID 's for this TestType
 | n=213 LabSpecimenID with two LabTest results
 | n=1 LabSpecimenID with three LabTest results
 | n=1 LabSpecimenID with four LabTest results
 *_______________________________________________________________________________________*/


*** 6.a) Records with duplicate LabSpecimenID that have 3 or 4 LabTest results  ***;
***-----------------------------------------------------------------------------***;

* Get LabSpecimenID for these records *;
   PROC print data=  Lab_TT437_Count; 
      where COUNT > 2 ;
      id LabSpecimenID; var COUNT;
run;

* Print data from  Lab_TT437_read  for these records *;
   PROC print data=  Lab_TT437_read; 
      where LabSpecimenID in (1595014, 2055207) ;
      id LabSpecimenID; by LabSpecimenID; 
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID ;
      format  ResultText $10. ;
run;

/*_______________________________________________________________________________________________________________*
 |FINDINGS:
 | LabSpecimenID = 1595014. This specimen is for EventID= 1081964 which is a deleted event.
 |    All 4 records have identical values for ResultID(=1061), ResultText(=B.1.1.7), ResultDate(=.), 
 |    CreateDate(=2021-06-10), and CreateByID(=13737).
 | LabSpecimenID = 2055207. This specimen is for EventID= 1209272 and entered via ELR.
 |    All 3 records have identical values for ResultID(=1061), ResultText(=B.1.1.7), ResultDate(=2021-06-24),
 |    CreateDate(=2021-06-25), and CreateByID(=13081).
 |FIX:
 | DeDUP based on LabSpecimenID, EventID, ResultID, ResultDate, CreateDate all being identical.
 *______________________________________________________________________________________________________________*/


*** 6.b) Records with duplicate LabSpecimenID that have 2 LabTest results  ***;
***-----------------------------------------------------------------------------***;

   proc sort data= &TT437dsn  
              out= TT437_Spec ;  
      by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
run;

** Calculate number of variables with identical values for Dups. Creates NumDupKey **;
DATA Two_TT437_Spec;  set TT437_Spec;
   by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
   where LabSpecimenID ^in (1595014, 2055207) ;

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

** See results - data with NumDupKeys **;
/*   PROC print data= Two_TT437_Spec; */
/*      where NumDupKeys > . ;*/
/*      var  LabSpecimenID EventID ResultID  ResultDate  CreateDate NumDupKeys  ; */
/*run;*/

**  Frequency of duplicates by the number of variables that are identical for the two results  **;
   PROC freq data= Two_TT437_Spec; 
      tables NumDupKeys; 
run;

/*______________________________________________________________________________________________________________*
 |FINDINGS:
 | n=36 records (18 pairs) with duplicate LabSpecimenID's have identical values in FOUR vars
 | FIX: DeDup on FOUR keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 |
 | n=62 records (31 pairs) with duplicate LabSpecimenID's have identical values in THREE vars
 | All but two of these pairs have ResultID in (1067, 1070). Were they re-sequenced?
 | FIX: DeDup on THREE keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 | Previous sort should be for descending CreateDate so this de-dup will keep most recent record.
 |
 | n=4 records (2 pairs) with duplicate LabSpecimenID's have identical values in TWO vars
 | These records have same ResultID and ResultText. The ResultDate differs because one value is missing.
 | FIX: Delete record with missing ResultDate.
 |
 | n=324 records (162 pairs) with duplicate LabSpecimenID's have identical values in ONE var (LabSpecimenID)
 | All but two of these pairs had ResultID= 1069 or 1070 for one record in duplicate pair.
 | The two exceptions had one record with result text that contained "LIKE".
 | FIX: delete record with ResultID= 1069 or 1070 and keep matching record with other ResultID.
 | FIX: delete record with result text that contains "LIKE".
 *_______________________________________________________________________________________________________________*/


**  Print records with duplicate LabTest results per Specimen  **;
**  that have FOUR variables that are identical between the two records **;
   PROC print data= Two_TT437_Spec; 
      where NumDupKeys=4;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT437dsn";
   title2 'NumDupKeys=4';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have THREE variables that are identical between the two records **;
   PROC print data= Two_TT437_Spec; 
      where NumDupKeys=3;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT437dsn";
   title2 'NumDupKeys=3';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have TWO variables that are identical between the two records **;
   PROC print data= Two_TT437_Spec; 
      where NumDupKeys=2;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT437dsn";
   title2 'NumDupKeys=2';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have only ONE variable that is identical between the two records **;
   PROC print data= Two_TT437_Spec; 
      where NumDupKeys=1;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT437dsn";
   title2 'NumDupKeys=1';
run;



***  7. Evaluate "ResultID" and "ResultText" variables  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT437dsn  ;
      tables ResultID / missing missprint;
      tables ResultID * ResultText /list; 
run;

/*_________________________________________________________________________________________________*
 |FINDINGS:
 | ResultID is the numeric code assigned to ResultText. In all but one case it is a 4 digit code.
 | ResultText holds the description of the sequencing result.
 |    ResultID=9 for ResultText = 'Unknown'
 |    ResultID=1061 is for ResultText = 'B.1.1.7 - for surveillance only...'
 |    ResultID=1062 is for ResultText = 'B.1.1.7 - like...'
 |    ResultID=1067 is for ResultText = 'Sequence inconclusive'
 |    ResultID=1068 is for ResultText = 'Unassigned variant'
 |    ResultID=1069 is for ResultText = 'Other'
 |    ResultID=1070 is for ResultText = 'Specimen unsatisfactory for evaluation'
 |    ResultID=1081 is for ResultText = 'B.1.617.2 - for surveillance only...'
 |    ResultID=1082 is for ResultText = 'B.1.617.2 - like...'
 |    etc.
 | Several results of the same variant type have different result text, i.e. "-like". 
 | FIX: re-format results to combine result text pairs into variant type.
 *___________________________________________________________________________________________________*/


***  8. Evaluate "ELRID" variable  ***;
***--------------------------------***;

   PROC freq data = &TT437dsn  ;
      tables ELRID / missing missprint;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | Almost a third of records are missing ELRID value
 | Otherwise, ELRID is a 6 digit ID unique for each record.
 *_______________________________________________________________________________________*/


***  9. Evaluate date variables  ***;
***------------------------------***;

   PROC means data = &TT437dsn  n nmiss ;
      var CreateDate  ResultDate  UpdateDate   ; 
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | CreateDate has no missing values. 
 | ResultDate is missing almost 10% of results. These dates shouldn't be missing. 
 | UpdateDate exists for less than 10% of results, which is fine.
 *_______________________________________________________________________________________*/


***  10. Explore relationship between CreateDate and ResultDate  ***;
***--------------------------------------------------------------***;

   PROC freq data = &TT437dsn  ;
      tables CreateDate  ResultDate ;
      format CreateDate  ResultDate  WeekW5. ;
run;
   PROC print data = &TT437dsn  ;
      where ResultDate > CreateDate ;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | CreateDate values begin week 3 of 2021 to the present. 
 | ResultDate values begin week 6 of 2020 to the present. 
 | No records have a ResultDate after CreateDate.
 *_______________________________________________________________________________________*/


***  11. Check for results = "Specimen unsatisfactory for evaluation"  ***;
***--------------------------------------------------------------------***;

   PROC freq data = &TT437dsn  ;
      tables ResultText ;
run;

/*___________________________________________________________________*
 |FINDINGS:  
 | n=3755 results where "Specimen unsatisfactory for evaluation"
 |FIX:
 | Delete these records
 *___________________________________________________________________*/



