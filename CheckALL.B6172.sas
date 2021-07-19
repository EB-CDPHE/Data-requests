/**********************************************************************************************
PROGRAM:  CheckALL.B6172
AUTHOR:   Eric Bush
CREATED:  July 15, 2021
MODIFIED: 070121:  Modified where clause to include Delta Plus variants
          063021:  Modify to be consistent with READ.SQL_DSN template
PURPOSE:	 Connect to CEDRS backend and create associated SAS dataset
INPUT:	 B6172_read        OR     COVID.B6172_fix
OUTPUT:	 printed output
***********************************************************************************************/

/*--------------------------------------------------------------------*
 | > Check dataset = B6172_read           v                         
 |   ___________________________________  v 
 | 1. Duplicate records (per ProfileID - EventID)
 | 2. Invalid values for CountyAssigned variable
 | 3. Check types of values for AgeType variable
 |
 | > Check dataset = COVID.B6172_fix      v
 |   ___________________________________  v 
 | 4. Invalid values for ICU variable
 | 5. 
 *--------------------------------------------------------------------*/

LIBNAME COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

**  Access the final SAS dataset that was created in the READ.B6172 program  **;

   PROC contents data= B6172_read  varnum ; run;


***  1. Duplicate records  ***;
***------------------------***;

* Identify duplicate records;
   PROC FREQ data= B6172_read noprint;  
      tables ProfileID * EventID / out=DupChk(where=(count>1));
   PROC print data=DupChk; 
      id ProfileID;
run;

/*__________________________________________________________________________________________*
 | FINDINGS:                                                                                |
 | This seems to be a regular occurrence. There are different types of dups.                |
 | Some differ on ResultDate. Fix: keep record with most recent (latest) ResultDate.        |
 | Some with identical ResultDate differ on CreateDate. Fix: keep record with latest date.  |
 | Some are identical on all varibles. Fix: keep last observation.                          |
 | Can accomplish all of these fixes by sorting by ResultDate and keeping last one.         |
 *__________________________________________________________________________________________*/


* Print out selected fields for ALL duplicate records *;
   proc sort data= B6172_read  out= B6172sort ;  by ProfileID  EventID ResultDate CreateDate ;
Data DupOnly;  merge B6172sort DupChk(in=Dup) ;  
 by ProfileID  EventID ;
 if Dup;
 run;

 options ps=50 ls=150 ;     * Landscape pagesize settings *;
   PROC print data= DupOnly;
      id ProfileID ; 
      var EventID gender birthdate ResultDate CreateDate  entrymethod  resulttext quantitativeresult  ;
      format lastname $15. ;
run;

/*     OR      */

* Print out duplicate records for specific Profile ID identified as having duplicate records *;
    PROC print data= B6172_read;
      where ProfileID='1658113';
      id ProfileID; 
      var EventID  lastname firstname birthdate gender disease eventstatus countyassigned entrymethod CreateDate ResultDate reporteddate age outcome testtype resulttext quantitativeresult  ;
run;
** FINDING:  the difference between the two is create date and result date variables.  Delete record with earlier result date  **;

   PROC print data= B6172_read;
      where ProfileID='1685685';
      id ProfileID; 
      var EventID  lastname firstname birthdate gender disease eventstatus countyassigned entrymethod CreateDate ResultDate reporteddate age outcome testtype resulttext quantitativeresult  ;
run;
** FINDING:  both records are completely the same  **;



***  2. Check County variable  ***;
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


* Print records where County name is NOT valid;
DATA B6172_Ck2; set B6172_read;
   keep ProfileID EventID County CountyAssigned ChkCounty;
   County = upcase(scan(CountyAssigned,1,','));
   ChkCounty = put(CountyAssigned, $CntyChk.);
   PROC print data= ChkCounty; 
      where ChkCounty='BAD COUNTY NAME';
run;

/*________________________________________________________________________*
 | FINDINGS:                                                              |
 | County_Assigned variable is in form of "County name, CO".              |
 | FIX: create new County variable from first 'word' of County_Assigned.  |
 | No county values that are bad, i.e. do not match list of CO counties.  |
 *________________________________________________________________________*/



***  3. Check Agetype variable  ***;
***-----------------------------***;

* Frequency of values of AgeType;
   PROC freq data= B6172_read; 
      tables AgeType;
run;

* Range of values of Age when AgeType = years;
   PROC univariate data= B6172_read; 
      where upcase(AgeType)='YEARS'; 
      var Age; 
run;

 * Print extreme values of Age when AgeType = years;
  PROC print data= B6172_read; 
      where upcase(AgeType) ^= 'YEARS'; 
      id ProfileID;
      var EventID LastName Gender Age AgeType Birthdate CreateDate ResultDate;
run;

/*_____________________________________________________________________________________*
 | FINDINGS:                                                                           |
 | Most all of the AgeType values are 'years' but a handful are days or months.        |
 | Look at birthdates for those where age type is not years to confirm newborn cases.  |
 | FIX: create new variable for Age_Years and convert weeks/months to age.             |
 | Format Age_Years variable to categorize cases into <70 and 70+ years of age.        |
 |                                                                                     |
 | NOTE: THIS EDIT IS DONE VIA FIX.CEDRS_VIEW PROGRAM                              |
 *_____________________________________________________________________________________*/



**  Access the edited SAS dataset that was created in the FIX.B6172 program  **;

   PROC contents data= COVID.B6172_fix  varnum ; run;




*** 4.  Post-edit checks ***;
***------____------------***;

* Check edits to ... *;
   PROC print data= COVID.B6172_fix(obs=50) ;
      id profileid ;  
      var gender disease eventstatus county entrymethod agetype outcome testtype resulttext eventid age birthdate reporteddate;
      format reporteddate mmddyy10.  ;
/*   tables CountyAssigned ;*/
run;


* Check edits to ... *;
   PROC freq data=COVID.B6172_fix; 
      tables gender disease eventstatus county entrymethod agetype outcome testtype resulttext  ; 
      format ResultText $variant.   ;
run;


* Check edits that converted all Age values to years  *;
   proc univariate data= COVID.B6172_fix;
      var Age Age_in_Years;
run;
