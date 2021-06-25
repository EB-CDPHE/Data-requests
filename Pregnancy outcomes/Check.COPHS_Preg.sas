/**********************************************************************************************
PROGRAM: Check.COPHS_Preg
AUTHOR:  Eric Bush
CREATED: June 24, 2021
MODIFIED:	
PURPOSE:	Check data in COPHS_Preg before filtering to target population
   Target population = females, 18-40 years old
INPUT:	COVID.COPHS_Preg
OUTPUT:	COVID.COPHS_Preg
***********************************************************************************************/

/*--------------------------------------------------------------------------------------------------------*
 | Table of Contents - code for the following tasks:
 |    1. Proc contents of basic COPHS dataset and the expanded COPHS dataset with pregnancy variables etc.
 |    2. Frequency of gender 
 |    3. Frequency of unknown DOB.
 |    4. N and number missing hospital admission date. --> impute with ICU admission date. 
 |    5. Frequency of Pregnant_at_Admit
 |    6. Create dataset for target population
 |       a) Filter out records with bad age data
 |       b) Fix Gender values
 |       c) Calculate Age at admission into Hospital
 |    7. Description of variables to be used to define target population
 |       a) univariate stats of good Age_at_Admit
 |       b) frequency of gender and categorization of Age_at_Admit
 |       c) Final N for target population
 *--------------------------------------------------------------------------------------------------------*/

options pageno=1;  title;

* 1. Proc contents of starting datasets *;

* basic COPHS *;
   PROC contents data=COVID.COPHS varnum; run;

* expanded COPHS *;
   PROC contents data=COVID.COPHS_Preg varnum ;  run;


* 2. Frequency of gender *;
   PROC freq data = COVID.COPHS_Preg ; tables gender; run;
   * FINDINGS:  some records have Gender=F instead of Gender=Female;


* 3. Frequency of unknown DOB *;
   PROC freq data= COVID.COPHS_Preg;  where DOB = '01JAN1900'd;  tables DOB; run;
   * n=1 record with unknown DOB;

* 4. N and number missing of hospital admission date ;
   PROC means data= COVID.COPHS_Preg n nmiss;
      var DOB  Hosp_Admit_Date  ICU_Admit_Date   ;
run;
* --> n=15 obs with missing hospital admission date;
   proc print data= COVID.COPHS_Preg ;  where Hosp_Admit_Date=.;  var MR_Number Last_name DOB Hosp_Admit_Date ICU_Admit_Date Gender; run;     *<-- Age_at_Admit=.;


* 5. Frequency of unknown DOB *;
   PROC freq data= COVID.COPHS_Preg;  *where DOB = '01JAN1900'd;  tables Pregnant_at_Admit; run;
   * FINDINGS:  some records have 'y' or 'yes' instead of 'Y';


* 6. Create dataset for target population *;
Data Cases_CBF_tmp ; set COVID.COPHS_Preg ;
* ignore records with DOB = Jan 1, 1990, i.e. unknown DOB ;
* ignore records with DOB during 2020 or 2021, i.e. 3 infants with COVID;
   where '01JAN1900'd < DOB < '01JAN2020'd;

* fix pregnant at admission values *;
   if Pregnant_at_Admit in ('y', 'yes') then Pregnant_at_Admit='Y';

* fix gender values *;
   if Gender='F' then Gender='Female';
   if Gender='M' then Gender='Male';

* accurate way to calculate age from two dates (per source below);
   Age_at_Admit = INT(Intck('MONTH', DOB, Hosp_Admit_Date)/12);
   If month(DOB) = month(Hosp_Admit_Date) then 
      Age_at_Admit = Age_at_Admit  -  (day(DOB)>day(Hosp_Admit_Date));
   *SOURCE: https://susanslaughter.files.wordpress.com/2010/08/61860_update_computingagesinsas.pdf ;

* For n=15 obs with missing Hosp_Admit_Date, then use ICU_Admit_date instead;
   if Hosp_Admit_Date=. then DO;
      Age_at_Admit = INT(Intck('MONTH', DOB, ICU_Admit_date)/12);
      If month(DOB) = month(ICU_Admit_date) then 
         Age_at_Admit = Age_at_Admit  -  (day(DOB)>day(ICU_Admit_date));
   END;
run;

* explore bad data;
   proc print data= CaseAge ;  where DOB='01JAN2020'd;  var MR_Number Last_name DOB Hosp_Admit_Date Age_at_Admit; run;   *<-- records with unknown DOB;
   proc print data= CaseAge ;  where Age_at_Admit=-1;  var MR_Number Last_name DOB Hosp_Admit_Date Age_at_Admit; run;     *<-- Age_at_Admit=-1;


*** Description of variables to be used to define target population. ***;
***__________________________________________________________________***;

* 7.a) univariate stats of good Age_at_Admit *;
   PROC univariate data= CaseAge ;
      var Age_at_Admit;
run;

   PROC format;
      value Age_Grp 
         low-17 = '1-17'
         18-40 = '18-40'
         41-high = 'Over 40' ;
run;

* 7.b) frequency of gender and categorization of Age_at_Admit *;
   PROC freq data = CaseAge ;
      tables Gender  Age_at_Admit  ;
      format Age_at_Admit Age_Grp. ;
run;

* 7.c) Final N for target population *;
   proc sort data=caseage out=casesbygender; by Gender;
   PROC freq data = casesbygender ;
      where gender='Female';
      tables Age_at_Admit  ;
      by Gender;
      format Age_at_Admit Age_Grp. ;
run;


