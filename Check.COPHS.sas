/**********************************************************************************************
PROGRAM:  Check.COPHS
AUTHOR:   Eric Bush
CREATED:  June 22, 2021
MODIFIED: 071921: Update per other RFI patterns for SAS programs.	
PURPOSE:	 After a SQL data table has been read using Read.CEDRS_SQL_table, this program can be used to explore the SAS dataset
INPUT:	 COVID.COPHS
OUTPUT:	 printed output
***********************************************************************************************/

/*--------------------------------------------------------------------------------------------------------*
 | Check COPHS data for:
 | 1. Duplicate records (per MR_Number)
 | 1.1 Duplicate records with same Hospital admission date
 | 2. Missing positive test dates
 | 3. Check that Grand county records are in Colorado and NOT Utah
 | 4. Invalid values for County_of_Residence variable
 *--------------------------------------------------------------------------------------------------------*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;


** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

options pageno=1;
title1 'dphe144 = COPHS';

   PROC contents data=COVID.COPHS varnum; run;

***  1. Duplicate records  ***;
***------------------------***;

* Identify duplicate records;
   PROC FREQ data= COVID.COPHS  noprint;  
      tables MR_Number / out=Hosp_DupChk(where=(COUNT>1));

* Print list of duplicate records;
   PROC print data=Hosp_DupChk; 
      id MR_Number;
run;

* Print record for specific MR_Number ID ;
   PROC print data= Hosp_DupChk;
      where MR_Number='1234567';
      id MR_Number; 
      var Facility_Name  Last_Name  First_Name  Hosp_Admission ;
run;

* Use dup record list to filter COPHS data for just dups (based on MR_Number)  *;
   proc sort data=COVID.COPHS(drop=filename)  out=COPHSdups  ; by MR_Number; run;
   proc sort data=Hosp_DupChk  ; by MR_Number; run;
DATA ChkCOPHSdups; merge COPHSdups DupChk(in=dup) ; 
   by MR_Number; 
   if dup;
run;

* Print out dup records with all vars from COPHS (based on MR_Number)  *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;
   PROC print data=ChkCOPHSdups ; 
      id MR_Number ;
      var Last_Name Gender Hosp_Admission Facility_Name Current_Level_of_care        
          Discharge_Transfer_Death_Disposi   Date_Left_Facility  ;
      format Last_Name $20.   Discharge_Transfer_Death_Disposi $20.  Facility_Name $40. ;
title2 'List of dup records';
run;


* 1.1): Print out dup records with same Hospital admission date (i.e. bad dup)  *;
   proc sort data=COVID.COPHS(where= (MR_Number in ('M1373870', 'M1535914')) ) out=DupHospAdmit; by MR_Number; run;
   PROC print data=DupHospAdmit ; 
      id MR_Number ;
      var Last_Name Gender Hosp_Admission Facility_Name Current_Level_of_care        
          Discharge_Transfer_Death_Disposi   Date_Left_Facility  ;
      format Last_Name $10.   Discharge_Transfer_Death_Disposi $20. Facility_Name $32. ;
title2 'List of dup records with same Hospital admission date';
run;

/*_____________________________________________________________________________________________________________________*
 | FINDINGS:
 | West Pines Hospital is mental facility associated with, i.e. on campus of, Exempla Lutheran Med Ctr.
 | --> Delete dup record where Facility = 'West Pines Hospital'. 
 | FIX:  Code to add in FIX.COPHS.sas program is:
 |    if MR_Number = 'M1373870' and Facility_Name = 'West Pines Hospital' then delete;
 |    if MR_Number = 'M1535914' and Hosp_Admission='08NOV20'd and Facility_Name = 'West Pines Hospital' then delete;
 *_____________________________________________________________________________________________________________________*/


options ps=65 ls=110 ;     * Portrait pagesize settings *;
title2 'ALL records';



***  2. Missing positive test dates - are they mostly recent admissions?  ***;
***-----------------------------------------------------------------------***;

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



***  3. Check that all Grand county records are in Colorado and NOT in Grand county, Utah  ***;
***----------------------------------------------------------------------------------------***;
   PROC freq data= COVID.COPHS;
      where upcase(County_of_Residence) = 'GRAND';
      tables  County_of_Residence * City * Zip_Code / list;
run;

/*______________________________________________________________________________________________________________*
 | FINDINGS:
 | Zip codes for Grand county Utah include:  84515, 84532, 84540
 |
 | FIX:
 |--> Delete records where Grand county Utah is place of residence. So code to add to data step below is:
 |    if upcase(County_of_Residence) = 'GRAND' and Zip_Code in (84515, 84532, 84540) then delete;
 *______________________________________________________________________________________________________________*/



***  4. Check county variable  ***;
***----------------------------***;

* Proc format to define valid Colorado county names;
   PROC format;   value $CntyChk
   'ADAMS'        = 'ADAMS'
   'ALAMOSA'      = 'ALAMOSA'
   'ARAPAHOE'     = 'ARAPAHOE'
   'ARCHULETA'    = 'ARCHULETA'
   'BACA'         = 'BACA'
   'BENT'         = 'BENT'
   'BOULDER'      = 'BOULDER'
   'BROOMFIELD'   = 'BROOMFIELD'
   'CHAFFEE'      = 'CHAFFEE'
   'CHEYENNE'     = 'CHEYENNE'
   'CLEAR CREEK'  = 'CLEAR CREEK'
   'CONEJOS'      = 'CONEJOS'
   'COSTILLA'     = 'COSTILLA'
   'CROWLEY'      = 'CROWLEY'
   'CUSTER'       = 'CUSTER'
   'DELTA'        = 'DELTA'
   'DENVER'       = 'DENVER'
   'DOLORES'      = 'DOLORES'
   'DOUGLAS'      = 'DOUGLAS'
   'EAGLE'        = 'EAGLE'
   'ELBERT'       = 'ELBERT'
   'EL PASO'      = 'EL PASO'
   'FREMONT'      = 'FREMONT'
   'GARFIELD'     = 'GARFIELD'
   'GILPIN'       = 'GILPIN'
   'GRAND'        = 'GRAND'
   'GUNNISON'     = 'GUNNISON'
   'HINSDALE'     = 'HINSDALE'
   'HUERFANO'     = 'HUERFANO'
   'JACKSON'      = 'JACKSON'
   'JEFFERSON'    = 'JEFFERSON'
   'KIOWA'        = 'KIOWA'
   'KIT CARSON'   = 'KIT CARSON'
   'LAKE'         = 'LAKE'
   'LA PLATA'     = 'LA PLATA'
   'LARIMER'      = 'LARIMER'
   'LAS ANIMAS'   = 'LAS ANIMAS'
   'LINCOLN'      = 'LINCOLN'
   'LOGAN'        = 'LOGAN'
   'MESA'         = 'MESA'
   'MINERAL'      = 'MINERAL'
   'MOFFAT'       = 'MOFFAT'
   'MONTEZUMA'    = 'MONTEZUMA'
   'MONTROSE'     = 'MONTROSE'
   'MORGAN'       = 'MORGAN'
   'OTERO'        = 'OTERO'
   'OURAY'        = 'OURAY'
   'PARK'         = 'PARK'
   'PHILLIPS'     = 'PHILLIPS'
   'PITKIN'       = 'PITKIN'
   'PROWERS'      = 'PROWERS'
   'PUEBLO'       = 'PUEBLO'
   'RIO BLANCO'   = 'RIO BLANCO'
   'RIO GRANDE'   = 'RIO GRANDE'
   'ROUTT'        = 'ROUTT'
   'SAGUACHE'     = 'SAGUACHE'
   'SAN JUAN'     = 'SAN JUAN'
   'SAN MIGUEL'   = 'SAN MIGUEL'
   'SEDGWICK'     = 'SEDGWICK'
   'SUMMIT'       = 'SUMMIT'
   'TELLER'       = 'TELLER'
   'WASHINGTON'   = 'WASHINGTON'
   'WELD'         = 'WELD'
   'YUMA'         = 'YUMA'
   other = 'BAD COUNTY NAME';
run;

* Count of records by formatted County name;
   PROC freq data= COVID.COPHS ;
      tables County_of_Residence;
      format County_of_Residence $CntyChk. ;
run;

* Print records where County name is NOT valid;
DATA ChkHospCounty; set COVID.COPHS;
   keep MR_Number Facility_Name  Last_Name  First_Name  Hosp_Admission ;
   ChkCounty = put(CountyAssigned, $CntyChk.);
   PROC print data= ChkHospCounty; 
      where ChkCounty='BAD COUNTY NAME';
run;


