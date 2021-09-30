/**********************************************************************************************
PROGRAM:  RFI.COPHS_Ethnicity_Race_Montezuma.sas
AUTHOR:   Eric Bush
CREATED:  September 29, 2021
MODIFIED:	
PURPOSE:	 RFI for COPHS hospitalization rate in Montezuma vs Colorado
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/


options pageno=1;

**  PROC contents of starting dataset  **;
   PROC contents data=COVID.COPHS_fix varnum;  title1 'COVID.COPHS_fix'; run;


**  Check structure (construction) of single_race_ethnicity variable on CEDRS  **;
   PROC freq data= COVID.CEDRS_view_fix ;
      table  Ethnicity * race * single_race_ethnicity / list ;
run;

   PROC freq data= COVID.COPHS_fix ;
      TABLE ChkCounty ;
run;


** Create dataset for response to this RFI **;

DATA COPHS_fixCY21; set COVID.COPHS_fix; 
   where Hosp_Admission ge '01JAN21'd  ; * AND  ChkCounty^='NON-COLO COUNTY NAME';

   if Ethnicity = 'Hispanic or Latino' then Ethnicity_Race = 'Hispanic, all races'; 
   else if Ethnicity = 'Non Hispanic or Latino' then DO;
      if Race = 'White' then Ethnicity_Race = 'Non-Hispanic, White';
      else if Race = 'Black, African American' then Ethnicity_Race = 'Non-Hispanic, Black';
      else Ethnicity_Race = 'Non-Hispanic, other races';
   END;  

   else if Ethnicity in ('Unknown or Unreported', 'Pre-Admission' ) then Ethnicity_Race = 'Ethnicity unknown';
   else Ethnicity_Race = 'NOT COUNTED';

   keep MR_Number  Facility_Name  Race  Ethnicity  Zip_Code  County_of_Residence    
        Hosp_Admission  Positive_Test  DOB  Ethnicity_Race;
run;

**  PROC contents of modified dataset  **;
   PROC contents data=COPHS_fixCY21 varnum;  title1 'COPHS_fixCY21'; run;


/*proc freq data= COPHS_fixCY21 ;  table Ethnicity * Race / list ; run;*/


options ps=50 ls=150 ;     * Landscape pagesize settings *;
proc freq data= COPHS_fixCY21 ;  table Ethnicity_Race * Ethnicity * Race / list ; run;


options ps=65 ls=110 ;     * Portrait pagesize settings *;
   proc freq data= COPHS_fixCY21 order=freq;  
      table Ethnicity_Race ; 
run;

** what is number hospitalized in CY21 in CO? **;
   proc means n nmiss data= COPHS_fixCY21;
      var Hosp_Admission DOB;
run;

**  How many unique patients in COPHS?  **;
   PROC SQL;
      select count(distinct MR_Number) as NumPeople
      from COPHS_fixCY21 ;
run;

/*---------------------------------------------------------------------------------------
 |FINDINGS:
 | n=20,144 obs. Hosp_Admission, DOB, and Ethnicity_Race are all complete.
 | n=18,969 distinct MR_Number (people).
 *---------------------------------------------------------------------------------------*/


** sort by date and Create patient-level dataset   **;
  PROC sort data=COPHS_fixCY21  
             out= COPHS_sort; 
      by MR_Number Hosp_Admission ;
run;

**  Reduce dataset from admission level to patient level  (one obs per patient)  **;
Data COPHS_patients; set COPHS_sort;
   by MR_Number;

* count cases per reported date *;
   if first.MR_Number then DO;  NumHosp=0; Hosp_Admission_first = Hosp_Admission;  END;
   retain Hosp_Admission_first;
   NumHosp+1;

* calculate case rate  *;
   if last.MR_Number then do;
      Hosp_Admission_last = Hosp_Admission;
/*      HospRate=  NumHosp  / (&ColoPop/100000);*/
      output;
   end;

   format Hosp_Admission_first  Hosp_Admission_last  mmddyy10.; 
* drop patient level variables  *;
   drop Hosp_Admission   ;
run;

**  PROC contents of patient-level dataset  **;
   PROC contents data=COPHS_patients varnum;  title1 'COPHS_patients'; run;


   *** check patient level data ***;

** what is number hospitalized in CY21 in CO? **;
   proc means n nmiss data= COPHS_patients;
      var Hosp_Admission_first  Hosp_Admission_last DOB;
run;

** what is number patients with two or more hosp admits in CY21? **;
   proc means n nmiss data= COPHS_patients;
      where Hosp_Admission_first ne Hosp_Admission_last;
      var Hosp_Admission_first  Hosp_Admission_last DOB;
run;



   proc freq data= COPHS_patients ;  
      table Hosp_Admission_first * Hosp_Admission_last/ list ; 
run;


*** Montezuma county  ***;
***-------------------***;

** what is number hospitalized in CY21 in MONTEZUMA? **;
   proc means n nmiss data= COPHS_patients;
      where  county_of_residence = 'MONTEZUMA';
      var Hosp_Admission_first  Hosp_Admission_last DOB;
run;

   proc freq data= COPHS_patients ORDER=FREQ;  
      where  county_of_residence = 'MONTEZUMA';
      table Ethnicity_Race; 
run;


   proc freq data= COPHS_patients ;  
      where  county_of_residence = 'MONTEZUMA'  AND  Ethnicity_Race ^in ('Ethnicity unknown','Non-Hispanic, Black');
      table Hosp_Admission_first  *  Ethnicity_Race / nocol norow; 
      format Hosp_Admission_first monyy.;
run;








   proc means n nmiss data= COPHS_fixCY21;
      var Hosp_Admission ;
      class county_of_residence;
run;

title;
proc print data=COVID.County_Population; run;

proc sort data= COPHS_fixCY21
            out= COPHS_sort;
   by Hosp_Admission;
run;

proc print data= COPHS_sort;
   where county_of_residence = 'MONTEZUMA';
   id Hosp_Admission; 
   var county_of_residence Ethnicity_Race DOB;
   format Hosp_Admission monyy.;
run;

proc freq data= COPHS_fixCY21;
   tables Hosp_Admission  Ethnicity_Race;
   format Hosp_Admission monyy.;
run;


libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;
DATA DASH.COPHS_fixCY21; set COPHS_fixCY21;
