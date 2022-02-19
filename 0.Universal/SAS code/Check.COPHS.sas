/**********************************************************************************************
PROGRAM:  Check.COPHS
AUTHOR:   Eric Bush
CREATED:  June 22, 2021
MODIFIED: 092921:  Add data checks for race var
          081221: Add data checks for a more comprehensive check of COPHS data
          071921: Update per other RFI patterns for SAS programs.	
PURPOSE:	 After a SQL data table has been read using Read.CEDRS_SQL_table, this program can be used to explore the SAS dataset
INPUT:	 COPHS_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

/*-----------------------------------------------------------------------------------------*
 | Data Checks for COPHS:
 | -->  ADMIT level variables  <--
 | a) missing hospital admit date
 | -->  PATIENT level variables  <--
 | 1. Duplicate records (per MR_Number)
 |    1.1) Records with 4 or more admissions
 |    1.2) Duplicate records with same Hospital admission date
 | 2. List of records with missing First name
 | 3. List of records with missing Last name
 | 4. Gender data
 | 5. City data
 | 6. Zip code data
 | 7. Check that Grand county records are in Colorado and NOT Utah
 | 8. Invalid values for County_of_Residence variable
 | 9. DOB
 | 10. Missing positive test dates


 | -->  HOSPITAL level variables  <--
 | 5. Invalid Hospital admission dates
 | 6. Race
 *-----------------------------------------------------------------------------------------*/


/*%LET ChkHospDSN = 'COPHS_read';       * <-- ENTER name of CEDRS dataset to run data checks against;*/

/*
| Proposed data checks:
| A. Admin. / key variables
|  1. MR_Number - number records; number distinct patients; dups
|  2. Data Structure - freq of hosp admits; list patients >3 admits
| B. Patient level variables
*/


** Access the final SAS dataset that was created in the Access.* program validated with the Check.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


   PROC contents data= COPHS_read varnum;  title1 'COPHS_read';  run;

***  a) Missing Hosp_Admission date  ***;
***-----------------------------------***;

**  Completeness of selected date variables  **;
   PROC means data= COPHS_read n nmiss ;
      var Hosp_Admission  DOB  Positive_Test;
run;

**  Completeness of selected date variables  **;
   PROC print data= COPHS_read  ;
      where Hosp_Admission=.;
      var Facility_Name MR_Number DOB  First_Name Last_Name Gender Race City County_of_Residence   Positive_Test;
run;

   PROC print data= COPHS_read  ;
      where Hosp_Admission=.  AND .< year(Positive_Test) <1901;
      var Facility_Name MR_Number DOB  First_Name Last_Name Gender Race City County_of_Residence   Positive_Test;
run;
/*------------
 |FINDINGS:
 | n=95 obs where Hosp_Admission=.
 | n=5 of them have valid data in other fields
 | n=90 of them have junk data. Seems like data is in wrong variables.
 | Remove these in Access.COPHS.sas since they impact variable length
 *----*/


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

**  Create dataset of patient IDs with multiple records / observations  **;
   PROC FREQ data= COPHS_read  noprint;  
      tables MR_Number / out=Hosp_DupChk(where=(COUNT>1));
run;

**  Frequency distribution of duplicate records  **;
   PROC freq data= Hosp_DupChk; 
      tables count;
run;
 
** 1.1) Records with 4 or more admissions  **;
 **  List of records with 4 or more admissions  **;
  PROC freq data= Hosp_DupChk; 
      where Count>3; 
      tables count*MR_Number/list nopercent nofreq nocum; 
run;

**  Create dataset of patients with 4 or more admissions  **;
DATA COPHS_HiDup; set COPHS_read(drop=Address_Line_1  Address_Line_2  filename  DateAdded);
      where MR_Number in ('1097954',  '1345065',   '1387869',  'CEUE01638818',  'CEUL2557164',  'H0452890',  'M000538741', 
                          'P0043691', 'S0134047',  'S0526208', 'S0540750', 'W00455941', 'W00519430', 'W00645967', '396653', 
                          'CEUE01337847', '2417438', 'W00703839', '20196926', 'W00120195', 'P0168646' );
run;

** Print data for records with 4 or more admissions  **;
   proc sort data=COPHS_HiDup ; by MR_Number Hosp_Admission ;  run;
   PROC print data=COPHS_HiDup; 
      id MR_Number;
      by MR_Number;
      var DOB Gender Hosp_Admission Facility_Name Current_Level_of_care        
          ICU_Admission   Date_Left_Facility   Discharge_Transfer_Death_Disposi   ;
      format Discharge_Transfer_Death_Disposi $20.  Facility_Name $40. ;   
run;

/*______________________________________________________________________________________________________________________*
 |FINDINGS (as of 8/4/21):
 | N=35,179 observations pulled from COPHS. N=33,678 distinct patients (MR_Number). (Therefore 1501 extra obs)
 | n=1 with missing hospital admission date.
 | n=9,396 with ICU admission date.
 |
 | n=1327 patients with multiple hosp admits, i.e. dup records.
 | n=21 patients with 4 or more visits to hospital.
 *______________________________________________________________________________________________________________________*/



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


** 1.2) Print dup records with same Hospital admission date (i.e. bad dup)  *;
proc sort data= COPHS_read  out=Hosp_sort(drop= filename);
   by MR_Number Hosp_Admission;
DATA DUP_Hosp_Admit;  set Hosp_sort; 
   by MR_Number Hosp_Admission;
   if first.Hosp_Admission ne last.Hosp_Admission;
run;
   PROC print data= DUP_Hosp_Admit; 
      id MR_Number;
      by MR_Number;
      var DOB Gender Hosp_Admission Facility_Name Current_Level_of_care        
          Discharge_Transfer_Death_Disposi   Date_Left_Facility  ;
      format Last_Name $10.   Discharge_Transfer_Death_Disposi $20. Facility_Name $32.  ;*DateAdded  mmddyy. ;
   title2 'List of dup records with same Hospital admission date';
run;

** 1.2) Print dup records with same Hospital admission date (i.e. bad dup)  *;
/*   proc sort data= COPHS_read(where= (MR_Number in ('M1373870', 'M1535914')) ) out=DupHospAdmit; by MR_Number; run;*/
/*   PROC print data=DupHospAdmit ; */
/*      id MR_Number ;*/
/*      var Last_Name Gender Hosp_Admission Facility_Name Current_Level_of_care        */
/*          Discharge_Transfer_Death_Disposi   Date_Left_Facility  ;*/
/*      format Last_Name $10.   Discharge_Transfer_Death_Disposi $20. Facility_Name $32. ;*/
/*title2 'List of dup records with same Hospital admission date';*/
/*run;*/

/*_____________________________________________________________________________________________________________________*
 | FINDINGS:
 | West Pines Hospital is mental facility associated with, i.e. on campus of, Exempla Lutheran Med Ctr.
 | --> Delete dup record where Facility = 'West Pines Hospital'. 
 | FIX:  Code to add in FIX.COPHS.sas program is:
 |    if MR_Number = 'M1373870' and Facility_Name = 'West Pines Hospital' then delete;
 |    if MR_Number = 'M1535914' and Hosp_Admission='08NOV20'd and Facility_Name = 'West Pines Hospital' then delete;
 *_____________________________________________________________________________________________________________________*/



***  2. First name  ***;
***------------------***;

** First name **;
   PROC freq data= COPHS_read;
      tables First_Name / missing missprint;
run;

** List of records with missing First name **;
   PROC print data= COPHS_read;
      where First_Name='';
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'Records with missing First Name';
run;

   PROC print data= COPHS_read;
      where length(First_Name) =1   AND  First_Name ^='' ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'First Name with only 1 letter';
run;

   PROC print data= COPHS_read;
      where countw(First_Name) >1   ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'First Name with > 1 word';
run;

   PROC print data= COPHS_read;
      where countw(First_Name) >1  AND  length(scan(First_Name,2,' ')) in (1,2) ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'First Name with > 1 word';
run;
/*________________________________________________________________________________________*
 |FINDINGS:
 | n=1069 records with missing First name (and most are missing Last name too).
 | n=28 records with single letter for first name
 | n=713 records with two part first name
 | n=498 records with middle initial
 *________________________________________________________________________________________*/


***  3. Last name  ***;
***------------------***;

   PROC freq data= COPHS_read;
      tables Last_Name / missing missprint;
run;


** List of records with missing Last name **;
   PROC print data= COPHS_read;
      where Last_Name='';
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'Records with missing First Name';
run;


   PROC print data= COPHS_read;
      where length(Last_Name) =1   AND  Last_Name ^='' ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'First Name with only 1 letter';
run;


   PROC print data= COPHS_read;
      where countw(Last_Name) >1   ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'Last Name with > 1 word';
run;

/*____________________________________________________________________________________*
 |FINDINGS:
 | n=1065 records with missing Last name (and most are missing First name too).
 | n=0 records with single letter for Last name
 | n=3241 records with two part Last name
 *____________________________________________________________________________________*/


***  4. Gender data  ***;
***------------------***;

** Gender **;
   PROC freq data= COPHS_read;
      where datepart(date_added) ^= '19FEB22'd ;
      tables Gender / missing missprint;
run;

/*____________________________________________________________________________________*
 |FINDINGS:
 | n=375 records where Gender = "F" (and not "Female").
 | n=430 records where Gender = "M" (and not "Male").
 | n=4 records where Gender = "Unknown"
 *____________________________________________________________________________________*/

   PROC print data= COPHS_read;
      where Gender in ('Unknown')  ;
      id MR_Number;
      by gender;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'Gender is Unknown';
run;

   PROC print data= COPHS_read;
      where ANYdigit(Gender)>0  ;
      id MR_Number;
/*      var  Hosp_Admission First_Name Last_Name DOB Gender city county_of_residence EventID;*/
      title2 'bad values for Gender';
run;



***  5. City  ***;
***-----------***;

** City **;
   PROC freq data= COPHS_read;
      tables City / missing missprint;
run;

   PROC print data= COPHS_read;
      where City in (' ')  ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city zip_code county_of_residence EventID;
      title2 'missing values for City';
run;

   PROC print data= COPHS_read;
      where City in ('.', '80011')  ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city zip_code county_of_residence EventID;
      title2 'bad values for City';
run;

   PROC print data= COPHS_read;
      where index(City,',')  ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'City values with commans';
run;

   PROC freq data= COPHS_read;
      where upcase(City)='AURORA';
      tables City / missing missprint;
run;

   PROC freq data= COPHS_read;
      where index(City,'CASTLE')  AND  index(City,'ROCK') ;
      tables City / missing missprint;
run;

   PROC freq data= COPHS_read;
      where index(City,'CO')  AND  index(City,'SP') ;
      tables City / missing missprint;
run;

   PROC print data= COPHS_read;
      where City = 'DFENVER'  ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'City values are misspelled';
run;

   PROC print data= COPHS_read;
      where City in ('NA', 'UNK', 'UNKNOWN', 'UNITED STATES AIR FORCE', 'USAF ACADEMY') ;
      id MR_Number;
      var  First_Name Last_Name DOB Gender city county_of_residence EventID;
      title2 'City values that are not city names';
run;

/*____________________________________________________________________________________*
 |FINDINGS:
 | n=43 records where City is missing
 | n=2 records with bad City value (City = . and City = 80011)
 | n=28 records where City has a comma
 | City values are UPCASE, lowercase, and PropCase, e.g. Aurora
 | City values have alternate spacing, e.g. Castle Rock
 | City values are abbreviated different ways, e.g. Colorado Springs
 | City values are misspelled, e.g. DFENVER
 | city values that are not city names, e.g. NA, UNK, USAF
 *____________________________________________________________________________________*/



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


**  Check zip codes that do not begin with 80 or 81  **;
proc sort data=sashelp.zipcode (keep=state county countynm  zip zip_class city city2 ) out=new (drop=zip_class);
by state county;
where missing(zip_class);
run;
   proc print data=new; run;


   PROC print data= COPHS_read ;
      where substr(Zip_Code, 1, 2) ^in ('80', '81');
      var MR_Number EventID city Zip_Code county_of_residence ;
run;

/*____________________________________________________________________________________*
 | FINDINGS:
 | Another approach besides singling out GRAND county in Utah would be zipcode.
 | All valid Colorado county names will have zip codes that begin with 80 or 81.
 | The problem with this is that many zip code values are bad.
 *_____________________________________________________________________________________*/



***  7. Check that all Grand county records are in Colorado and NOT in Grand county, Utah  ***;
***----------------------------------------------------------------------------------------***;

   PROC freq data= COPHS_read;
      where upcase(County_of_Residence) = 'GRAND';
      tables  CO * County_of_Residence * City * Zip_Code / list;
run;

/*______________________________________________________________________________________________________________*
 | FINDINGS:
 | Zip codes for Grand county Utah include:  84515, 84532, 84540
 |
 | FIX:
 |--> Delete records where Grand county Utah is place of residence. So code to add to data step below is:
 |    if upcase(County_of_Residence) = 'GRAND' and Zip_Code in (84515, 84532, 84540) then delete;
 *______________________________________________________________________________________________________________*/


***  8. Check county variable  ***;
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
   other = 'NON-COLO COUNTY NAME';
run;

* Count of records by formatted County name;
   PROC freq data= COPHS_read ;
      tables County_of_Residence / missing missprint;
      format County_of_Residence $CntyChk. ;
run;

* Print records where County name is NOT valid;
DATA ChkHospCounty; set COPHS_read;
   keep MR_Number Facility_Name County_of_Residence Last_Name  First_Name  Hosp_Admission ChkCounty  CO;
   ChkCounty = put(County_of_Residence, $CntyChk.);
   PROC print data= ChkHospCounty; 
      where ChkCounty='NON-COLO COUNTY NAME';
run;


***  9. DOB  ***;
***----------***;

**  How many COPHS records are there?  **;
   PROC means data= COPHS_read n nmiss ;
      var Hosp_Admission  ICU_Admission  DOB  Positive_Test;
run;

**  How many unique patients in COPHS?  **;
   PROC SQL;
      select count(distinct DOB) as BirthDates
      from COPHS_read ;
run;

DATA Birthday; set COPHS_read;
Birth_Month = month(DOB);
Birth_Day = day(DOB);
keep MR_Number EventID DOB Birth_Month Birth_Day ;
run;
   PROC sort data= Birthday  out=DOB_sort ; by Birth_Month Birth_Day;

   PROC freq data= DOB_sort ;
/*      tables DOB / missing missprint;*/
      tables Birth_Month * Birth_Day * DOB / list  out=DOBCHK;
      format DOB MMDDYY5. ;
run;
proc print data= DOBCHK; run;


proc univariate data= DOBCHK freq;
var count;
run;

proc print data= COPHS_read; 
where put(DOB, MMDDYY5.) = '02/29';
run;
proc print data= COPHS_read; 
where put(DOB, MMDDYY5.) = '01/01';
run;

proc univariate data= DOBCHK freq;
where put(DOB, MMDDYY5.) ^= '02/29'  AND  put(DOB, MMDDYY5.) ^= '01/01';
var count;
run;



***  10. Missing positive test dates - are they mostly recent admissions?  ***;
***-----------------------------------------------------------------------***;

/*
|FINDINGS:  This should be re-run after removing readmits      <---*
*/

options ps=65 ls=110 ;     * Portrait pagesize settings *;
* count *;
   proc means data=COPHS_read n nmiss;
      var Positive_Test;
run;

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








***  7. Invalid values of Discharge_Transfer_Death_Disposi variable  ***;
***------------------------------------------------------------------***;

   PROC freq data= COPHS_read ;
      tables Discharge_Transfer_Death_Disposi / missing missprint ;
run;

/*_____________________________________________________________________________*
 |FINDINGS:
 | n=2 "died" and n=1 "other" (all lower case).  FIX: change to propcase.
 | n=3 "OTHER". FIX: change to propcase.
 *______________________________________________________________________________*/


***  7. Hospital admissin after Discharge_Transfer_Death_Disposi = 'DIED'  ***;
***------------------------------------------------------------------------***;

**  Create dataset of records where reason left was "DIED" but have later hospital admission date  **;
DATA Hosp_Admit_after_Died;  set Hosp_sort; 
   by MR_Number Hosp_Admission;

   if PropCase(Discharge_Transfer_Death_Disposi) = "Died"  AND  last.MR_Number = 0 ;* AND lag(DOB) = DOB;
run;

**  Print out MR_Number and use to print all hospital admissions from COPHS_read  **;
   PROC print data= Hosp_Admit_after_Died;
      id MR_Number;
      var DOB Gender  County_of_Residence   Facility_Name   Positive_Test   Hosp_Admission   ICU_Admission  Died_in_ICU__Y_N_   Discharge_Transfer_Death_Disposi  ;
run;

**  Print out all hospital admissions for patient who died and had subesquent hospital admission  **;
   PROC print data= Hosp_sort;
      where MR_Number in ('1387869', 'CEUL0139998', 'CEUL1984469' );
      id MR_Number;
      by MR_Number;
      var DOB Gender  Facility_Name   Positive_Test   Hosp_Admission   ICU_Admission  Died_in_ICU__Y_N_   Discharge_Transfer_Death_Disposi  ;
      title2 'Patients that died AND have subesquent hospital admission';
      format Facility_Name $30.  ;*Discharge_Transfer_Death_Disposi  City $15. ;
run;

proc contents data= Hosp_sort varnum ; run;



*** Check values of Race variables ***;
***--------------------------------***;

   PROC freq data= COPHS_read ;
      tables  Race  Ethnicity ; 
run;

/*-----------------------------------------------------------------------*
 |FINDINGS:
 | n=1 "AA" and n=1 "AS".  FIX: Change to "Unknown or Unreported"
 | n=1 "ASIAN".  FIX: Race=PropCase(Race)
 | n=1  "American Indian Alaska Native"  FIX: Add "/"
 | n=128 "CA".  FIX:  Change to "Caucasian"
 | n=13 "HI" and n=14 "HISPANIC".  FIX: Change to "Unknown or Unreported"
 | n=1 "OT".  FIX: Change to "Other"
 | n=1 "Other Race".  FIX: Change to "Other".
 | n=3 "Native Hawaiian or Other Pacific Islan".  
 |     FIX:  Change to "Pacific Islander/Native Hawaiian"
 |
 | n=1 "Declined to specify".   FIX: Change to "Unknown or Unreported"
 | n=1 "Non-Hispanic or Latino".   FIX: remove '-'
 *-----------------------------------------------------------------------*/

PROC format;
   value $RaceFmt  "More than one Race", "Other Race" = "Other" ;
   value $EthnicFmt 
      "Declined to specify", "Pre-Admission" = "Unknown or Unreported"
      "Non-Hispanic or Latino" = "Non Hispanic or Latino" ;

   PROC freq data= COPHS_read ;
      tables  Race  Ethnicity ; *  Single.race.ethnicity_with_CIIS ;
      format  Race  $RaceFmt38.  Ethnicity  $EthnicFmt22. ;
run;

   PROC freq data= COPHS_read ;
      tables  Ethnicity * Race  /list ; *  Single.race.ethnicity_with_CIIS ;
      format  Race  $RaceFmt38.  Ethnicity  $EthnicFmt22. ;
run;



*** CO=1 for County outside of Colorado ***;
***-------------------------------------***;

* Print records where County name is NOT valid;
DATA Chk_CO_resident; set COPHS_read;
   keep MR_Number Facility_Name County_of_Residence Last_Name  First_Name address_line_1 city zip_code  Hosp_Admission ChkCounty  CO;
   ChkCounty = put(County_of_Residence, $CntyChk.);
run;

options ps=50 ls=150 ;     * Landscape pagesize settings *;
   PROC print data= Chk_CO_resident; 
      where CO=1  AND  ChkCounty='NON-COLO COUNTY NAME';
      id MR_Number; var Facility_Name Hosp_Admission   CO address_line_1 city zip_code County_of_Residence     ;
      format Facility_Name  $40.  address_line_1 $30.  city $20.  ;
      title1 'COPHS_read';
      title2 'NON-COLO COUNTY NAME';
run;

   PROC print data= Chk_CO_resident; 
      where CO=0  AND  ChkCounty^='NON-COLO COUNTY NAME';
      id MR_Number; var Facility_Name Hosp_Admission   CO address_line_1 city zip_code County_of_Residence     ;
      format Facility_Name  $40.  address_line_1 $30.  city $20.  ;
      title1 'COPHS_read';
      title2 'Valid COLO COUNTY NAME BUT CO=0';
run;


options ps=65 ls=110 ;     * Portrait pagesize settings *;
