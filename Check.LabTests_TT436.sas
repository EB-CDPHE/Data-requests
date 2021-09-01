/**********************************************************************************************
PROGRAM:  Check.LabTests_TT436
AUTHOR:   Eric Bush
CREATED:  August 27, 2021
MODIFIED: 090121
PURPOSE:	 After a SQL data table has been read using Access.LabTests_TT437, 
            this program can be used to explore the SAS dataset.
INPUT:	 Lab_TT436_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

%Let TT436dsn = Lab_TT436_read ;

options pageno=1;
   PROC contents data=Lab_TT436_read  varnum ;  title1 'Lab_TT436_read';  run;

/*--------------------------------------------------------------------*
 | Check Lab_TT436_read data for:
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
 *--------------------------------------------------------------------*/


***  1. Compare "CreateBY" and "CreatedBY" variables  ***;
***---------------------------------------------------***;

   PROC means data = &TT436dsn  n nmiss ;
      var CreateBYID   CreatedBYID   ; 
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | CreateBYID has no missing responses
 | CreateDbyID only has 500 responses, most are missing.
 | ** DO NOT USE CreateDbyID
 *_______________________________________________________________________________*/


***  2. Evaluate "CreateByID" and "CreateBy" variables  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT436dsn  order=freq;
      tables CreateByID * CreateBy /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | CreateByID is the numeric code assigned to names
 | CreateBy holds the names. Same connection as TestTypeID=437.
 | Almost 90% of VOC results were created by 8 people:
 |    Sara Kitchen (23%), Christina Goode (21%), Emily Hentz Leister (14%), 
 |    Elizabeth Sogunle (9%), Keelin Bettridge (6%), Breanna Kawasaki (6%), 
 |    Lauren Caggiano (5%), Alisa Chaisitti (4%)
 | n=26 different individuals have created lab tests results,
 | including "System Admin" (ID=9999)
 | n=9 individuals have created fewer than 10 lab tests results.
 *_______________________________________________________________________________*/


***  3. Evaluate "ResultID" and "ResultText" variables  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT436dsn  ;
      tables ResultID / missing missprint;
      tables ResultID * ResultText /list; 
run;

/*_________________________________________________________________________________________________________*
 |FINDINGS:
 | ResultID is the numeric code assigned to ResultText. In all but one case it is a 4 digit code.
 | ResultText holds the description of the sequencing result.
 |    ResultID=9 for ResultText = 'Unknown'
 |    ResultID=1071 is for ResultText = 'Yes'
 |    ResultID=1072 is for ResultText = 'No'
 | n=1 record has a missing Result. LabSpecimenID=2162300 and EventID=1232059 with CreateDate=2021-08-06
 *_________________________________________________________________________________________________________*/

* Print data for this record *;
   PROC print data=  &TT436dsn ; 
      where ResultID = . ;
      id LabSpecimenID; var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID;
run;


***  4. Explore relationship between LabID and LabSpecimenID  ***;
***-----------------------------------------------------------***;

  PROC means data = &TT436dsn  n nmiss ;
      var LabID  LabSpecimenID   ; 
run;

/*   PROC freq data = &TT437dsn;  tables LabID  LabSpecimenID  ;  run;*/

/*_______________________________________________________________________________________*
 |FINDINGS:
 | Records with duplicate LabSpecimenID have same EventID but different, unique LabID's
 | In other words, a LabSpecimenID can have multiple LabID's.
 *_______________________________________________________________________________________*/


***  5. Examine records with duplicate LabSpecimenID's  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT436dsn  NOPRINT;
      tables  LabSpecimenID / out=Lab_TT436_Count ;
   PROC freq data = Lab_TT436_Count;
      tables COUNT;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | LabID:  No values are missing. This is a 7 digit ID unique for each record
 | LabSpecimenID:  No values are missing. This is a 6 or 7 digit ID. Most are unique.
 | N = 27,745 records with LabSpecimenID. Most records have only 1 LabSpecimenID.  
 | N = 25,592 unique LabSpecimenID 's for this TestType
 | n=151 LabSpecimenID with two LabTest results
 | n=1 LabSpecimenID with three LabTest results
 *_______________________________________________________________________________________*/


*** 5.a) Record with duplicate LabSpecimenID that has 3 LabTest results  ***;
***----------------------------------------------------------------------***;

* Get LabSpecimenID for these records *;
   PROC print data=  Lab_TT436_Count; 
      where COUNT > 2 ;
      id LabSpecimenID; var COUNT;
run;

* Print data from  Lab_TT437_read  for these records *;
   PROC print data=  Lab_TT436_read; 
      where LabSpecimenID in (1772736) ;
      id LabSpecimenID; by LabSpecimenID; 
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID ;
      format  ResultText $10. ;
run;

/*_______________________________________________________________________________________________________________*
 |FINDINGS:
 | LabSpecimenID = 1772736. This specimen is for EventID= 1112136.
 |    Two records have identical values for ResultID(=1071), ResultText(=Yes), ResultDate(=.), 
 |    CreateDate(=2021-05-25), and CreateByID(=13508).
 |    The other record has ResultID(=9), ResultText(=Unknown), ResultDate(=2021-04-23), 
 |    CreateDate(=2021-04-27), and CreateByID(=13410).
 |FIX:
 | First delete record with ResultID=9. This will leave two records with identical values on FOUR variables.
 | DeDUP other two records based on LabSpecimenID, EventID, ResultID, ResultDate, CreateDate all being same.
 *______________________________________________________________________________________________________________*/


*** 5.b) Records with duplicate LabSpecimenID that have 2 LabTest results  ***;
***-----------------------------------------------------------------------------***;

   proc sort data= &TT436dsn  
              out= TT436_Spec ;  
      by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
   data TT436_Spec; set TT436_Spec;
      if LabSpecimenID in (1772736) AND ResultID=9 then delete ;  * if delete this 1 record the other two will have NumDupKeys=4;
run;

** Calculate number of variables with identical values for Dups. Creates NumDupKey **;
DATA Two_TT436_Spec;  set TT436_Spec;
   by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 

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
   PROC freq data= Two_TT436_Spec; 
      tables NumDupKeys; 
run;

/*______________________________________________________________________________________________________________*
 |FINDINGS:
 | n=10 records with duplicate LabSpecimenID's have identical values in FOUR vars
 | FIX: DeDup on FOUR keys using PROC SORT NODUPKEY option (which keeps the FIRST obs).
 |
 | n=22 records (11 pairs) with duplicate LabSpecimenID's have identical values in TWO vars
 | These records have same ResultID and ResultText. The ResultDate differs because one value is missing.
 | FIX: Delete record with missing ResultDate.
 |
 | n=272 records (136 pairs) with duplicate LabSpecimenID's have identical values in ONE var (LabSpecimenID)
 | All but four of these pairs had ResultID= 9 (ResultText='Unknown') for one record in duplicate pair.
 | The four exceptions had one record with result text = 'Yes' and the other result = 'No'.
 | FIX: since all four mixed result dups have been sequenced, keep record where result = 'Yes'.
 | FIX: delete record with ResultID= 9 and keep matching record with other ResultID.
 *_______________________________________________________________________________________________________________*/


**  Print records with duplicate LabTest results per Specimen  **;
**  that have FOUR variables that are identical between the two records **;
   PROC print data= Two_TT436_Spec; 
      where NumDupKeys=4;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT436dsn";
   title2 'NumDupKeys=4';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have TWO variables that are identical between the two records **;
   PROC print data= Two_TT436_Spec; 
      where NumDupKeys=2;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT436dsn";
   title2 'NumDupKeys=2';
run;


**  Print records with duplicate LabTest results per Specimen  **;
**  that have only ONE variable that is identical between the two records **;
   PROC print data= Two_TT436_Spec; 
      where NumDupKeys=1;
      id LabSpecimenID;
      by LabSpecimenID;
      var EventID ResultID ResultText ResultDate CreateDate LabID ELRID CreateByID  NumDupKeys ;
      format  ResultText $10. ;
   title1 "Source data = &TT436dsn";
   title2 'NumDupKeys=1';
run;


***  6. Evaluate date variables  ***;
***------------------------------***;

   PROC means data = &TT436dsn  n nmiss ;
      var CreateDate  ResultDate  UpdateDate   ; 
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | CreateDate has no missing values. 
 | ResultDate is missing almost 40% of results. These dates shouldn't be missing. 
 | UpdateDate exists for less than 2% of results, which is fine.
 *_______________________________________________________________________________________*/


***  7. Explore relationship between CreateDate and ResultDate  ***;
***--------------------------------------------------------------***;

   PROC freq data = &TT436dsn  ;
      tables CreateDate  ResultDate ;
      format CreateDate  ResultDate  WeekW5. ;
run;
   PROC print data = &TT436dsn  ;
      where ResultDate > CreateDate ;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | CreateDate values begin week 3 of 2021 to the present. 
 | ResultDate values begin week 6 of 2020 to the present. 
 | No records have a ResultDate after CreateDate.
 *_______________________________________________________________________________________*/









