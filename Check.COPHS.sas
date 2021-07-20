/**********************************************************************************************
PROGRAM:  Check.COPHS
AUTHOR:   Eric Bush
CREATED:  June 22, 2021
MODIFIED: 071921: Update per other RFI patterns for SAS programs.	
PURPOSE:	 After a SQL data table has been read using Read.CEDRS_SQL_table, this program can be used to explore the SAS dataset
INPUT:	 COPHS_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

/*-----------------------------------------------------------------------------------------*
 | Check COPHS data for:
 | 1. Duplicate records (per MR_Number)
 | 1.1 Duplicate records with same Hospital admission date
 | 2. Missing positive test dates
 | 3. Check that Grand county records are in Colorado and NOT Utah
 | 4. Invalid values for County_of_Residence variable
 | 5. Invalid Hospital admission dates
 *-----------------------------------------------------------------------------------------*/


/*%LET ChkHospDSN = 'COPHS_read';       * <-- ENTER name of CEDRS dataset to run data checks against;*/


** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


   PROC contents data= COPHS_read varnum; run;


***  1. Duplicate records  ***;
***------------------------***;

* Identify duplicate records;
   PROC FREQ data= COPHS_read  noprint;  
      tables MR_Number / out=Hosp_DupChk(where=(COUNT>1));

* Print list of duplicate records;
   PROC print data=Hosp_DupChk; 
      id MR_Number;
run;

* Print record for specific MR_Number ID ;
   PROC print data= COPHS_read;
      where MR_Number='1006415';
      id MR_Number; 
      var Facility_Name  Last_Name  First_Name  Hosp_Admission ;
run;

* Use dup record list to filter COPHS data for just dups (based on MR_Number)  *;
   proc sort data= COPHS_read(drop=filename)  out=COPHSdups  ; by MR_Number; run;
   proc sort data=Hosp_DupChk  ; by MR_Number; run;
DATA ChkCOPHSdups; merge COPHSdups Hosp_DupChk(in=dup) ; 
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
   proc sort data= COPHS_read(where= (MR_Number in ('M1373870', 'M1535914')) ) out=DupHospAdmit; by MR_Number; run;
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



***  2. Missing positive test dates - are they mostly recent admissions?  ***;
***-----------------------------------------------------------------------***;

options ps=65 ls=110 ;     * Portrait pagesize settings *;
* details *;
proc print data= COPHS_read;
   where Positive_Test = .;
   var MR_Number  Last_Name Gender County_of_Residence  Hosp_Admission  Date_left_facility;
run;

* summary ;
   proc format; 
      value YNfmt  . = 'Missing date'  other='Have date' ;
   PROC freq data= COPHS_read;
      where Hosp_Admission > '31DEC20'd  AND  Hosp_Admission < '31JUL21'd;
      tables Positive_Test * Hosp_Admission /missing missprint norow nopercent;
      format Positive_Test YNfmt.        Hosp_Admission MONYY. ;
run;



***  3. Check that all Grand county records are in Colorado and NOT in Grand county, Utah  ***;
***----------------------------------------------------------------------------------------***;
   PROC freq data= COPHS_read;
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
   PROC freq data= COPHS_read ;
      tables County_of_Residence / missing missprint;
      format County_of_Residence $CntyChk. ;
run;

* Print records where County name is NOT valid;
DATA ChkHospCounty; set COPHS_read;
   keep MR_Number Facility_Name County_of_Residence Last_Name  First_Name  Hosp_Admission ChkCounty;
   ChkCounty = put(County_of_Residence, $CntyChk.);
   PROC print data= ChkHospCounty; 
      where ChkCounty='BAD COUNTY NAME';
run;


***  5. Invalid Hospital Admission dates  ***;
***---------------------------------------***;

**  Check range of hospital admission dates  **;
   PROC freq data= COPHS_read ;
      tables Hosp_Admission;
run;

**  Print out extreme observations  **;

options ps=50 ls=150 ;     * Landscape pagesize settings *;

  PROC print data= COPHS_read ;
      where  (. < Hosp_Admission < '01JAN20'd)  OR  (Hosp_Admission > '01DEC21'd) ;
      id MR_Number ;
      var Hosp_Admission Facility_Name First_Name Last_Name Gender DOB Positive_Test Date_Left_Facility City County_of_Residence  ;
      format Facility_Name $45. First_Name Last_Name  $12.  City $15. ;
      title2 'Extreme values of hospital admission dates from COPHS';
run;

** Create dataset for exporting **;
Data BadHospAdmit; set COPHS_read ;
      where  (. < Hosp_Admission < '01JAN20'd)  OR  (Hosp_Admission > '01DEC21'd) ;
run;

/*___________________________________________________________________________________________________________________________*
 | FINDINGS:
 | 1) n=6 records admitted to Estes Park Medical Center 11/1/2019 - before the pandemic started in CO. 
 |    They had positive test dates and left the hospital in fall 2020.
 |    FIX: Change hospital admit date to 11/1/2020
 | 2) n=1 admitted to Vail Health on 3/22/1921. 
 |    FIX: Change hospital admit date to 3/22/2021.
 | 3) n=2 will be admitted this December right after christmas. 
 |    FIX: Change hospital admit date 2020 instead of 2021. 
 | 4) MR_Number=CEUL2893910 was admitted on 7/3/18 and has yet to leave the facility. He had a positive test on 11/10/20.
 | 5) MR_Number=161782665 was admitted on 11/30/2019 and left the facility on 4/9/2020. Tested positive on  3/18/2020.
 |    This is plausible. If true, they would be one of the first COVID hospitalization in Colorado. 
 *____________________________________________________________________________________________________________________________*/

