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

   if index(result,'POS')>0  OR result ='DETECTED' then ResultGroup='POSITIVE';
   else if index(result,'NEG')>0  OR result ='NOT DETECTED' then ResultGroup='NEGATIVE';
   else ResultGroup='UNKNOWN';
run;

options pageno=1;
   PROC contents data=ELR_Filtered  varnum ;  title1 'ELR_Filtered';  run;

/*%Let TT229dsn = Lab_TT229_reduced ;*/

/*------------------------------------------------------------------------------*
 | Check Lab_TT229_read data for:
 | 1. Check Lab * Test_Type to compare to Tableau crosstab
   2. Check Result grouping
 | 3. Check duplicate PatientID
 | 4. Check duplicate Person_ID
 | 5. Evaluate date variables
 *------------------------------------------------------------------------------*/


***  1. Check Lab * Test_Type  ***;
***----------------------------***;

   PROC freq data= ELR_Filtered; 
      tables lab * test_type; 
run;


***  2. Check Result grouping  ***;
***----------------------------***;

   PROC freq data= ELR_Filtered; 
      where ResultGroup ^= 'UNKNOWN';  
      tables Result * ResultGroup /nopercent norow nocol ; 
run;

** Tally ResultGroup **;
   PROC freq data= ELR_Filtered; 
      tables ResultGroup  ; 
run;


***  3. Check Check duplicate PatientID  ***;
***--------------------------------------***;

* Count number of obs by PatientID *;
   PROC freq data = ELR_Filtered  noprint ;
      tables PatientID /out=PatientCount; 
run;
   proc freq data=PatientCount ; tables count; run;

* Restrict dataset to just PatientID's with >1 obs *;
DATA DupPatients; set PatientCount;
   where count>1;
run;

* Use list of dup PatientID's to restrict main data *;
   proc sort data= ELR_Filtered
               out= ELR_Patient ;
      by PatientID;
run;

DATA DupELRPatients; merge ELR_person DupPatients(in=p) ; 
   by PatientID;

   if p;
run;

* Evaluate PatientIDs with two obs *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;
proc print data=DupELRPatients ; 
      ID PatientID;
      var Person_ID  Gender  DateAdded SpecimenType COVID19Negative  Test_Type  Result  ResultGroup  Lab CollectionDate  ;
      format Person_ID $40.  SpecimenType $20.  Result $15. Test_Type lab $10. ;
run;

/*----------------------------------------------------------*
 FINDINGS:
   n=795 obs with dup PatientID. 
   There can be multiple PatientID for same Person_ID
 FIX:
   Re-do check based on Person_ID instead of PatientID
 QUESTION:
   What is difference between PatientID and PersonID?
 *----------------------------------------------------------*/



***  4. Check duplicate Patients ***;
***------------------------------***;

* Count number of obs by Person_ID *;
   PROC freq data = ELR_Filtered  noprint ;
      tables Person_ID /out=PersonCount; 
run;
   proc freq data=PersonCount ; tables count; run;

* Create dataset of Person_ID's with 2 obs or 3+ obs *;
DATA  TwoTests ThreePlusTests; set PersonCount;
   if count ne 1;

   if count=2 then output TwoTests;
   if count>2 then output ThreePlusTests;
run;

* Use list of dup Person_ID's to restrict main data *;
   proc sort data= ELR_Filtered
               out= ELR_Person ;
      by Person_ID;
run;

DATA Persons_w_2tests; merge ELR_person TwoTests(in=s2) ; 
   by Person_ID;

   if s2;
run;

* Evaluate Person_ID's with two obs *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;
proc print data=Persons_w_2tests ; 
      ID Person_ID ;
      var  PatientID  Gender  DateAdded SpecimenType COVID19Negative  Test_Type  Result  ResultGroup  Lab CollectionDate  ;
      format Person_ID $40.  SpecimenType $20.  Result $15. Test_Type lab $10. ;
run;





/*----------------------------------------------------------*
 FINDINGS:
   What is Person_ID = *CSL* about?
   Reasons for 2 records per Person:
   1) Collection date > X days apart --> separate diagnostic events
   2) Collection date < X days apart --> single diagnostic event, e.g. QT / isolation
   3) Collection dates are same and same specimen type and result --> true duplicate



*/

   PROC means data= Persons_w_2tests  n nmiss;
      var DateAdded  CollectionDate;
run;


* sort by CollectionDate *;
   proc sort data= Persons_w_2tests
               out= TallDSN1 ;
      by Person_ID  CollectionDate;
run;

* transpose CollectionDate *;
   PROC transpose data=TallDSN1  
   out=WideDSN1(drop= _NAME_)
      prefix=CollectDate ; 
      var CollectionDate;          
      by Person_ID;  
run;
/*   proc print data= WideDSN1; format Person_ID $40. ; run;*/

libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;
DATA DASH.WideDSN1_new; set WideDSN1;
CollectionDate_Diff = CollectDate2 - CollectDate1;
run;
   proc print data= DASH.WideDSN1_new; format Person_ID $40. ; run;
   proc freq data= DASH.WideDSN1_new; table CollectionDate_Diff ; run;



   PROC transpose data=Persons_w_2tests  
   out=WideDSN2(drop= _NAME_)
      prefix=DateAdded ; 
      var DateAdded;          
      by Person_ID;  
run;
   proc print data= WideDSN2; format Person_ID $40. ; run;

* transpose SpecimenType *;
   PROC transpose data=Persons_w_2tests  
   out=WideDSN3(drop= _NAME_)
      prefix=SpecimenType ; 
      var SpecimenType;          
      by Person_ID;  
run;
   proc print data= WideDSN3; format Person_ID $40. ; run;

* transpose Test_Type *;
   PROC transpose data=Persons_w_2tests  
   out=WideDSN4(drop= _NAME_)
      prefix=Test_Type ; 
      var Test_Type;          
      by Person_ID;  
run;
   proc print data= WideDSN4; format Person_ID $40. ; run;

* transpose Result *;
   PROC transpose data=Persons_w_2tests  
   out=WideDSN5(drop= _NAME_)
      prefix=Result ; 
      var Result;          
      by Person_ID;  
run;
   proc print data= WideDSN5; format Person_ID $40. ; run;

* transpose ResultGroup *;
   PROC transpose data=Persons_w_2tests  
   out=WideDSN6(drop= _NAME_)
      prefix=ResultGroup ; 
      var ResultGroup;          
      by Person_ID;  
run;
   proc print data= WideDSN6; format Person_ID $40. ; run;


DATA ELR_Person_2obs; merge  WideDSN1  WideDSN2  WideDSN3  WideDSN4  WideDSN5  WideDSN6  ;
      by Person_ID;  
      var  PatientID  Gender  DateAdded SpecimenType COVID19Negative  Test_Type  Result  ResultGroup  Lab CollectionDate  ;
      format Person_ID $40.  SpecimenType $20.  Result $15. Test_Type lab $10. ;

run;








