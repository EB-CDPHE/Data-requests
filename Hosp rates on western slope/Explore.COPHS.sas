/**********************************************************************************************
PROGRAM: Explore.COPHS
AUTHOR:  Eric Bush
CREATED: June 22, 2021
MODIFIED:	
PURPOSE:	After a SQL data table has been read using Read.CEDRS_SQL_table, this program can be used to explore the SAS dataset
INPUT:		[name of input data table(s)]
OUTPUT:		[name of output - SAS data tables, printed output, etc]
***********************************************************************************************/

/*--------------------------------------------------------------------------------------------------------*
 | Table of Contents - code for the following tasks:
 |    1. Proc contents of COPHS dataset
 |    2. Identify duplicate records. 
 |    3. Print selected variables for duplicate records.
 |       a) Look at dup records with same Hospital admission date
 |    4. Explore records with missing positive COVID test date 
 |    5. Check that Grand county records are in Colorado and NOT Utah
 |    6. Check for counties that do not match Colorado counties, i.e. misspelled
 *--------------------------------------------------------------------------------------------------------*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;


** Access the final SAS dataset that was created in the Read.* program that matches this Explore.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

options pageno=1;
title1 'dphe144 = COPHS';

   PROC contents data=COVID.COPHS varnum; run;


*** The first part of this code is focused on looking at data quality type issues ***;
***_______________________________________________________________________________***;

* 2: Identify duplicate records *;
   PROC FREQ data= COVID.COPHS  noprint;  
      tables MR_Number / out=DupChk(where=(COUNT>1));
/*   PROC print data=DupChk;  id MR_Number; var Count;  run;*/

* 3: Print out dup records (based on MR_Number)  *;
   proc sort data=COVID.COPHS(drop=filename)  out=COPHSdups  ; by MR_Number; run;
   proc sort data=DupChk  ; by MR_Number; run;
DATA ChkCOPHSdups; merge COPHSdups DupChk(in=dup) ; 
   by MR_Number; 
   if dup;
run;

options ps=50 ls=150 ;     * Landscape pagesize settings *;

   PROC print data=ChkCOPHSdups ; 
      id MR_Number ;
      var Last_Name Gender Hosp_Admission Facility_Name Current_Level_of_care        
          Discharge_Transfer_Death_Disposi   Date_Left_Facility  ;
      format Last_Name $20.   Discharge_Transfer_Death_Disposi $20.  Facility_Name $40. ;
title2 'List of dup records';
run;


* 3.a): Print out dup records with same Hospital admission date (i.e. bad dup)  *;
   proc sort data=COVID.COPHS(where= (MR_Number in ('M1373870', 'M1535914')) ) out=DupHospAdmit; by MR_Number; run;
   PROC print data=DupHospAdmit ; 
      id MR_Number ;
      var Last_Name Gender Hosp_Admission Facility_Name Current_Level_of_care        
          Discharge_Transfer_Death_Disposi   Date_Left_Facility  ;
      format Last_Name $10.   Discharge_Transfer_Death_Disposi $20. Facility_Name $32. ;
title2 'List of dup records with same Hospital admission date';
run;

/*-----------------------------------------------------------------------------------------------------------------------*
 | FINDINGS:
 | West Pines Hospital is mental facility associated with, i.e. on campus of, Exempla Lutheran Med Ctr.
 | --> Delete dup record where Facility = 'West Pines Hospital'. So code to add to data step below is:
     if MR_Number = 'M1373870' and Facility_Name = 'West Pines Hospital' then delete;
     if MR_Number = 'M1535914' and Hosp_Admission='08NOV20'd and Facility_Name = 'West Pines Hospital' then delete;
*------------------------------------------------------------------------------------------------------------------------*/


options ps=65 ls=110 ;     * Portrait pagesize settings *;
title2 'ALL records';

** 4. Explore missing positive test dates to see if they are mostly recent admissions **;
* details *;
proc print data=COVID.COPHS;
   where Positive_Test = .;
   var MR_Number Last_Name Gender County_of_Residence Hosp_Admission Date_left_facility;
run;

* summary ;
   proc format; 
      value YNfmt  . = 'Missing date'  other='Have date' ;
   PROC freq data= COVID.COPHS;
      where Hosp_Admission > '31DEC20'd  AND  Hosp_Admission < '31JUL21'd;
      tables Positive_Test * Hosp_Admission /missing missprint norow nopercent;
      format Positive_Test YNfmt.        Hosp_Admission MONYY. ;
run;


** 5. Check that all Grand county records are in Colorado and NOT in Grand county, Utah **;
   PROC freq data= COVID.COPHS;
      where upcase(County_of_Residence) = 'GRAND';
      tables  County_of_Residence * City * Zip_Code / list;
run;
/*-----------------------------------------------------------------------------------------------------------------------*
 | FINDINGS:
 | Zip codes for Grand county Utah include:  84515, 84532, 84540
 | --> Delete records where Grand county Utah is place of residence. So code to add to data step below is:
     if upcase(County_of_Residence) = 'GRAND' and Zip_Code in (84515, 84532, 84540) then delete;
*------------------------------------------------------------------------------------------------------------------------*/

** 6. Check all counties are valid Colorado counties **;


