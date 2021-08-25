/*----------------------------------------------------------------------------*
 PROGRAM:  Tall2Wide_transpose.sas
 Purpose: Transpose long dataset with multiple variables to wide dataset 
 *----------------------------------------------------------------------------*/

/*____________________________________________________________________________*
 | Patient level variables:  MR_Number;  Name
 | Hospital level variables: Hosp_Name; Visit; ICU; RsnLeft
 | Some patients have multiple hospital admissions.
 | To get patient level dataset, have to transpose hospital level variables.
 *____________________________________________________________________________*/

DATA HospVisits;
   input MR_Number $ Name $ Hosp_Name $ Visit ICU RsnLeft ;
   datalines;
   A Alice Exempla 1 0 1
   B Bob   PVH     1 0 2
   C Carol Kaiser  1 0 3
   D Doug  SCL     1 1 4
   E Eric  MCR     1 0 1
   B Bob   PVH     2 1 3
   E Eric  MCR     2 1 4
   ;
run;
proc print data= HospVisits; run;


** Macro template **;
   proc sort data= HospVisits out=HV_sort; by MR_Number Name ;                  * sort by patient level key variables;
PROC transpose data=HV_sort  out=HospVar1(drop= _NAME_)  prefix=Hosp_Name; 
   by MR_Number Name;                                                            * will create one row for each value ;
   var Hosp_Name;                                                                * hospital level variables to be transposed;
run;
proc print data= HospPatients2; run;


** Macro definition **;
%macro Tall2Wide(dsn, tdsn, byvar, tvar);
PROC transpose data=&dsn  out=&tdsn(drop= _NAME_)  prefix=&tvar; 
   by &byvar;  
   var &tvar;          
run;
%mend;


** Call macro  **;
   proc sort data= HospVisits out=HV_sort; by MR_Number Name ;  * sort by patient level key variables;
%Tall2Wide(HV_sort, HV1, Hosp_Name)
%Tall2Wide(HV_sort, HV2, Visit)
%Tall2Wide(HV_sort, HV3, ICU)
%Tall2Wide(HV_sort, HV4, RsnLeft)


** Merge datasets together  **;
Data HospPatient2;  merge HV1-HV4;
   by MR_Number ;
run;

proc print data= HospPatient2; id MR_Number; run;









