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
/*   PROC contents data=LabTests_TT437  varnum ;  title1 'LabTests_TT437';  run;*/


**  Compare "CreateBY" and "CreatedBY" variables  **;
   PROC means data = &TT437dsn  n nmiss ;
      var CreateBYID   CreatedBYID   ; 
run;
/*_______________________________________________________________________________*
 |FINDINGS:
 | CreateBYID has no missing responses
 | CreateDbyID only has 1200 responses, most are missing.
 | ** DO NOT USE CreateDbyID
 *_______________________________________________________________________________*/


**  Evaluate "CreateByID" and "CreateBy" variables  **;
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


**  Evaluate "UpdatedBy" variables  **;
   PROC freq data = &TT437dsn  ;
/*      tables  UpdatedBy;*/
      tables CreateByID *  UpdatedBy /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | UpdatedBy holds the names of individuals that updated lab results.
 | UpdatedBy does NOT match (or align with) CreateByID.
 *_______________________________________________________________________________*/


**  Evaluate "TestBrandID" and "TestBrand" variables  **;
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


 **  Explore relationship between LabID and LabSpecimenID  **;
  PROC means data = &TT437dsn  n nmiss ;
      var LabID  LabSpecimenID   ; 
run;

   PROC freq data = &TT437dsn;
      tables LabID  LabSpecimenID  ;
run;

**  Get frequency of records with duplicate LabSpecimenID's  **;
   PROC freq data = &TT437dsn;
      tables  LabSpecimenID / out=Lab_TT437_Count ;
   PROC freq data = Lab_TT437_Count;
      tables  count;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | LabID:  No values are missing. This is a 7 digit ID unique for each record
 | LabSpecimenID:  No values are missing. This is a 6 or 7 digit ID. Most are unique.
 |    n=213 duplicate LabSpecimenID 
 |    n=1 with 3 and 4 counts respectively
 *_______________________________________________________________________________________*/



**  Print records with duplicate LabSpecimenID's  **;
   proc sort data= &TT437dsn  out= Lab_TT437_Sort(keep= EventID  LabID  LabSpecimenID) ;  
      by LabSpecimenID  LabID  ;
DATA Multi_TT437_Spec;   set Lab_TT437_Sort;
   by LabSpecimenID  LabID  ;
   if first.LabSpecimenID ne last.LabSpecimenID;
run;
   PROC print data= Multi_TT437_Spec;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | Records with duplicate LabSpecimenID have same EventID but different, unique LabID's
 | In other words, a LabSpecimenID can have multiple LabID's.
 *_______________________________________________________________________________________*/




**  Evaluate "ResultID" and "ResultText" variables  **;
   PROC freq data = &TT437dsn  ;
      tables ResultID / missing missprint;
      tables ResultID * ResultText /list; 
run;

/*_________________________________________________________________________________________________*
 |FINDINGS:
 | ResultID is the numeric code assigned to ResultText. In all but one case it is a 4 digit code.
 | ResultText holds the description of the sequencing result.
 |    ResultID=9 for ResultText = 'Unknown'
 |    ResultID=1067 is for ResultText = 'Sequence inconclusive'
 |    ResultID=1068 is for ResultText = ' Unassigned variant'
 |    ResultID=1069 is for ResultText = 'Other'
 |    ResultID=1070 is for ResultText = 'Specimen unsatisfactory for evaluation'
 |
 | Several results of the same variant type have different result text. 
 | FIX: re-format results.
 *___________________________________________________________________________________________________*/


**  Evaluate "ELRID" variable  **;
   PROC freq data = &TT437dsn  ;
      tables ELRID / missing missprint;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | Almost a third of records are missing ELRID value
 | Otherwise, ELRID is a 6 digit ID unique for each record.
 *_______________________________________________________________________________________*/


 **  Evaluate data variables  **;
  PROC means data = &TT437dsn  n nmiss ;
      var CreateDate  ResultDate  UpdateDate   ; 
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | CreateDate has no missing values. 
 | ResultDate is missing almost 10% of results. These dates shouldn't be missing. 
 | UpdateDate exists for less than 10% of results, which is fine.
 *_______________________________________________________________________________________*/


 **  Explore relationship between CreateDate and ResultDate  **;
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








