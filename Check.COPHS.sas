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

**  How many COPHS records are there?  **;
   PROC means data= COPHS_read n nmiss ;
      var Hosp_Admission  ICU_Admission  DOB  Positive_Test;
run;

**  How many unique patients in COPHS?  **;
   PROC SQL;
      select count(distinct MR_Number) as NumPeople
      from COPHS_read ;
run;

**  Create dataset of patients with multiple records / observations  **;
   PROC FREQ data= COPHS_read  noprint;  
      tables MR_Number / out=Hosp_DupChk(where=(COUNT>1));
run;

**  Frequency distribution of duplicate records  **;
   PROC freq data= Hosp_DupChk; 
      tables count;
run;
 
 **  List of records with 4 or more admissions  **;
  PROC freq data= Hosp_DupChk; 
      where Count>3; 
      tables count*MR_Number/list nopercent nofreq nocum; 
run;

   proc sort data=COPHS_read out=Dup_Sort ; by MR_Number Hosp_Admission ;
** Print data for records with 4 or more admissions  **;
   PROC print data=Dup_Sort; 
      where MR_Number in ('1097954',  '1345065',   '1387869',  'CEUE01638818',  'CEUL2557164',  'H0452890',  'M000538741', 
                          'P0043691', 'S0134047',  'S0526208', 'S0540750', 'W00455941', 'W00519430', 'W00645967', '396653', 
                          'CEUE01337847', '2417438', 'W00703839', '20196926', 'W00120195', 'P0168646' );
      id MR_Number;
      by MR_Number;
        var Last_Name Gender Hosp_Admission Facility_Name Current_Level_of_care        
          Discharge_Transfer_Death_Disposi   Date_Left_Facility  ;
      format Last_Name $20.   Discharge_Transfer_Death_Disposi $20.  Facility_Name $40. ;   
run;

* Print record for specific MR_Number ID ;
   PROC print data= COPHS_read;
      where MR_Number='1006415';
      id MR_Number; 
      var Facility_Name  Last_Name  First_Name  Hosp_Admission ;
run;

* Use list of dup records to filter COPHS data for just dups (based on MR_Number)  *;
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


* 1.2) Frequency of dup records   *;


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

*** 5.1) Print obs with missing Hospital admission date ***;
   PROC print data= COPHS_read ;
      where Hosp_Admission = . ;
      id MR_Number ;
      var Hosp_Admission Facility_Name First_Name Last_Name Gender DOB Positive_Test Date_Left_Facility City County_of_Residence  ;
      format Facility_Name $45. First_Name Last_Name  $12.  City $15. ;
      title1 'DATA =  COPHS_read';
      title2 'missing Hospital admission date';
run;

*** 5.1.1) Print out records for patient with missing Hospital admission date ***;
   PROC print data= COPHS_read ;
      where MR_Number = 'M1660961' ;
      id MR_Number ;
      var Hosp_Admission Facility_Name First_Name Last_Name Gender DOB Positive_Test Date_Left_Facility City County_of_Residence  DateAdded;
      format Facility_Name $45. First_Name Last_Name  $12.  City $15. ;
      title1 'DATA =  COPHS_read';
      title2 'Patient with missing Hospital admission date';
run;




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



***  6. Invalid zip codes  ***;
***------------------------***;
**  Check range of zip codes  **;
   PROC freq data= COPHS_read ;
      tables Zip_Code ;
run;
/*___________________________________________________________________________________________________________________________*
 | FINDINGS:
 | Several issues with Zip_Code values.
 | 1) n=22 zip codes only have 3 or 4 digits to them. In almost all cases these are missing leading 0 or 00.
 |    FIX: Add leading 0's.
 | 2) n=20 zip codes only have 1 or 2 digits. Most have an Address of "GENERAL DELIVERY".  What does that mean?
 | 3) n=17 zip codes are missing
 | 4) n=11 records have zip code=99999.
 |    FIX: Zip code = missing
 | 5) n=1 zip code = 'UNKNO'
 |    FIX: Zip code = missing
 *____________________________________________________________________________________________________________________________*/

Data COPHS_Ck6 ; set COPHS_read;
   ZipCode_length = length(Zip_Code);
run;

   PROC print data= COPHS_Ck6 ;
      where ZipCode_length in (3, 4);
      id MR_Number ;
      var  Hosp_Admission Facility_Name Last_Name Address_Line_1  City Zip_Code County_of_Residence  Discharge_Transfer_Death_Disposi  ZipCode_length  ;
      format Facility_Name $45.  Address_Line_1 $25.   First_Name Last_Name   $12.  Discharge_Transfer_Death_Disposi  City $15. ;
run;
/*___________________________________________________________________________________________________________________________*
 | FINDINGS:
 | City=WYCKOFF has Zip_Code=7481.  FIX: Change Zip_Code to 07481 (for Wyckoff, NJ).
 | City=Groton has Zip_Code=1450.  FIX: Change Zip_Code to 01450 (for Groton, MA).
 | City=Leesburg has Zip_Code=8327.  FIX: Change Zip_Code to 08327 (for Leesburg, NJ).
 | City=Pompton Lakes has Zip_Code=7442.  FIX: Change Zip_Code to 07442 (for Pompton Lakes, NJ).
 | City=Provincetown has Zip_Code=2657.  FIX: Change Zip_Code to 02657 (for Provincetown, MA).
 | City=Auckland. This is a valid zip code for Auckland, New Zealand.
 | City=Guatemala has Zip_Code=1012.  FIX: Change Zip_Code to 01012 (for Guatemala).
 | City=Andover has Zip_Code=7821.  FIX: Change Zip_Code to 07821 (for Andover, NJ).
 | City=Newington has Zip_Code=3801.  FIX: Change Zip_Code to 03801 (for Newington, NH).
 | City=Epsom has Zip_Code=3234.  FIX: Change Zip_Code to 03234 (for Epsom, NH).
 | City=Egg Harbor has Zip_Code=8234.  FIX: Change Zip_Code to 08234 (for Egg Harbor, NJ).
 | City=Morristown has Zip_Code=7960.  FIX: Change Zip_Code to 07960 (for Morristown, NJ).
 | City=Tenafly has Zip_Code=7670.  FIX: Change Zip_Code to 07670 (for Tenafly, NJ).
 | City=Providence has Zip_Code=2906.  FIX: Change Zip_Code to 02906 (for Providence, RI).
 | City=Westfield has Zip_Code=7090.  FIX: Change Zip_Code to 07090 (for Westfield, NJ).
 | City=Old Greenwich has Zip_Code=6870.  FIX: Change Zip_Code to 06870 (for Old Greenwich, CT).
 | City=Methuen has Zip_Code=1844.  FIX: Change Zip_Code to 01844 (for Methuen, MA).
 |
 | Zip_Code=962.  FIX: Change Zip_Code to 00962 (for Catano, PR).
 | City=Barranquitas has Zip_Code=794.  FIX: Change Zip_Code to 00794 (for Barranquitas, PR).
 *____________________________________________________________________________________________________________________________*/


   PROC print data= COPHS_Ck6 ;
      where ZipCode_length in (1, 2)   AND  Zip_Code ne '' ;
      id MR_Number ;
      var Last_Name  Hosp_Admission Facility_Name Address_Line_1  City Zip_Code County_of_Residence   ZipCode_length  ;
      format Facility_Name $30.  Address_Line_1 $25.   First_Name Last_Name   $12.  Discharge_Transfer_Death_Disposi  City $15. ;
run;


   PROC print data= COPHS_read ;
      where Zip_Code ='';
      id MR_Number ;
      var Last_Name  Hosp_Admission Facility_Name Address_Line_1  City  Zip_Code  County_of_Residence     ;
      format Facility_Name $40.  Address_Line_1 $25.   First_Name Last_Name   $12.  Discharge_Transfer_Death_Disposi  City $15. ;
run;

   PROC print data= COPHS_read ;
      where Zip_Code in ('99999','UNKNO');
      id MR_Number ;
      var Last_Name  Hosp_Admission Facility_Name Address_Line_1  City  Zip_Code  County_of_Residence     ;
      format Facility_Name $40.  Address_Line_1 $25.   First_Name Last_Name   $12.  Discharge_Transfer_Death_Disposi  City $15. ;
run;
