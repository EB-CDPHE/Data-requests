/**********************************************************************************************
PROGRAM:  Check.ELR_Full
AUTHOR:   Eric Bush
CREATED:  January 5, 2022
MODIFIED: 
PURPOSE:	 After a SQL data table has been read using Access.LabTests_TT229, 
            this program can be used to explore the SAS dataset.
INPUT:	 Lab_TT229_read
OUTPUT:	 printed output
***********************************************************************************************/
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/
options ps=65 ls=110 ;     * Portrait pagesize settings *;


*** Filter data to PCR results added since July 1, 2021 ***;
***-----------------------------------------------------***;
DATA ELR_Filtered;  set ELR_Full;
   where DateAdded ge '01JUL21'd;
run;

options pageno=1;
   PROC contents data=ELR_Filtered   ;  title1 'ELR_Filtered';  run;

%Let TT229dsn = Lab_TT229_reduced ;

/*------------------------------------------------------------------------------*
 | Check Lab_TT229_read data for:
 | 1. Compare "CreateBY" and "CreatedBY" variables
 | 2. Evaluate "ResultID" and "ResultText" variables
 | 3. Examine records with duplicate LabSpecimenID's
 |    a) Records with duplicate LabSpecimenID that have > 2 LabTest results 
 |    b) Records with duplicate LabSpecimenID that have 2 LabTest results
 | 4. Evaluate date variables
 *------------------------------------------------------------------------------*/

proc freq data= ELR_Filtered; tables lab * test_type; run;


***  2. Evaluate "ResultID" and "ResultText" variables  ***;
***-----------------------------------------------------***;

   PROC freq data = &TT229dsn  ;
      tables ResultID * ResultText /list missing missprint; 
/*      tables QuantitativeResult ; */
run;


