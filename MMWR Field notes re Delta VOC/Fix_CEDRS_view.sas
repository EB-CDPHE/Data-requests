/**********************************************************************************************
PROGRAM: Fix.CEDRS_view
AUTHOR:  Eric Bush
CREATED:	July 6, 2021
MODIFIED:	
PURPOSE:	Explore created SAS dataset
INPUT:	COVID.CEDRS_view    zDSI_Events_fix
OUTPUT:	COVID.CEDRS_view_fix
***********************************************************************************************/

/*-----------------------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 | 1. Create County variable from County_Assigned that only includes county name (not ", CO" too)
 | 2. Impute missing values of Age_at_Reported with Age_in_Years from dphse66 zDSI_Events_fix. See NOTE.
 | 3. Contents of final dataset
 |
 | 4. Post-edit data checks on COVID.CEDRS_view_fix
 *-----------------------------------------------------------------------------------------------------------*/

** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COVID.CEDRS_view varnum; run;
   PROC contents data=zDSI_Events_fix varnum; run;


/*____________________________________________________________________________________________________________________*
 | NOTE:                                                                                                              |
 | The variable Age on zDSI_Events is coupled to the Age_Type variable.                                               |
 | Values of Age can be years, months, weeks, or days.                                                                |
 | The FIX.zDSI_Events program was written to convert all age types into years and place in a new variable.           |
 | The new variable, "Age_in_Years", is merged with CEDRS_view and used to impute missing values of Age_at_Reported.  |
 *____________________________________________________________________________________________________________________*/


***  Make edits to CEDRS_view and create COVID.CEDRS_view_fix  ***;
***------------------------------------------------------------***;

   proc sort data=zDSI_Events_fix  out=AgeVar(keep=ProfileID EventID Age_Years Age)  ; by ProfileID EventID ;
   proc sort data=COVID.CEDRS_view  out=CEDRS_NoAge   ; by ProfileID EventID ;
DATA COVID.CEDRS_view_fix; 
   merge CEDRS_NoAge AgeVar ; 
   by ProfileID EventID ;

** 1) new county variable  **;
   County = upcase(scan(CountyAssigned,1,',')); 
 
** 2) impute missing values of Age_at_Reported  **;
   if Age=. AND Age_Years=. then Age_Years = Age_at_Reported;
   if Age_Years > 109 then Age_Years = . ;

run;


**  3. Contents of final SAS dataset  **;

   PROC contents data=COVID.CEDRS_view_fix varnum; run;



*** Post-edit checks ***;
***------------------***;

proc univariate data= COVID.CEDRS_view_fix; var Age_years; run;
proc means data= COVID.CEDRS_view_fix  n nmiss min p1 p10 p25 median mean p75 p90 p99 max   maxdec=2; var Age_years; run;

proc means data= COVID.CEDRS_view_fix  n nmiss min p10 p25 median mean p75 p90 max   maxdec=2; var Age_years; run;


proc print data = MMWR_cases;
where Age_years = .;
id ProfileID;
var EventID Age_Years Age Age_Group County CollectionDate ReportedDate hospitalized ;
run;



proc print data=MMWR_cases ;
id ProfileID; var EventID Age Age_Group Age_at_reported Age_Years County ;
run;





