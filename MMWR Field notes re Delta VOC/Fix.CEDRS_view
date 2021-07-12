/**********************************************************************************************
PROGRAM: Fix.CEDRS_view
AUTHOR:  Eric Bush
CREATED:	July 6, 2021
MODIFIED:	
PURPOSE:	Explore created SAS dataset
INPUT:	      CEDRS_view
OUTPUT:	COVID.CEDRS_view_fix
***********************************************************************************************/


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COVID.CEDRS_view varnum; run;

/*
 | Fixes made in this code:
   1. Remove dup records by keeping record with latest ResultDate 
   2. Create County variable from County_Assigned that only includes county name (not ", CO" too)
*/


** Need to fix ages **;
   ** to do that need to read in age variable from Events **;
   ** then merge Age-in_years variable with CEDRS_view_fix  **;

LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;         * <--  Changed BK's libname ; 

** 2. Read in the first 50 records to create sample SAS dataset **;
DATA zDSI_Events; set CEDRS66.zDSI_Events(keep=ProfileID EventID Disease EventStatus AgeTypeID AgeType Age   MedicalRecordNumber); 
   if disease ='COVID-19'  AND   EventStatus in ('Probable','Confirmed') ;
run;    

** Review contents of SAS dataset **;
PROC contents data=zDSI_Events  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA zDSI_Events_temp; set zDSI_Events(rename=(EventID=tmp_EventID ProfileID=tmp_ProfileID )); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);
   ProfileID = cats(tmp_ProfileID);
   DROP tmp_:  ;
run;

** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(zDSI_Events_temp)

** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA zDSI_Events_read ; set zDSI_Events_temp_ ;
run;

   PROC contents data=zDSI_Events_read varnum; run;


** 1. Create Age in years variable from other Age Type records **;
DATA zDSI_Events_fix ;  set zDSI_Events_read ;
   if upcase(AgeType) = 'DAYS' then Age_Years = Age/365;
   if upcase(AgeType) = 'WEEKS'  then Age_Years = Age/52;
   if upcase(AgeType) = 'MONTHS' then Age_Years = Age/12;
   if upcase(AgeType) = 'YEARS'  then Age_Years = Age;
   Label Age_Years = 'Age in years';
run;


** 2. Add new Age in years variable and create new County name variable  **;
   proc sort data=zDSI_Events_fix   out=AgeVar(keep=ProfileID EventID Age_Years Age)  ; by ProfileID EventID ;
   proc sort data=COVID.CEDRS_view   out=CEDRS_NoAge   ; by ProfileID EventID ;
DATA COVID.CEDRS_view_fix; merge CEDRS_NoAge AgeVar ; by ProfileID EventID ;
   County = upcase(scan(CountyAssigned,1,','));         * <-- a) new county variable ;
   if Age=. AND Age_Years=. then Age_Years = Age_at_Reported;
run;


   PROC contents data=COVID.CEDRS_view_fix varnum; run;


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





