/**********************************************************************************************
PROGRAM:  RFI.COPHS_rates_CO_Hispanic.sas
AUTHOR:   Eric Bush
CREATED:  September 30, 2021
MODIFIED:	
PURPOSE:	 RFI on creating chart that compares hosp rate (7d mov avg) for MOntezuma vs CO
INPUT:	 COVID.COPHS_fix	
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/


*** Create timeline of all dates ***;
***------------------------------***;

DATA timeline;
   Hosp_Admission_first='01JAN20'd;
   output;
   do t = 1 to 638;
      Hosp_Admission_first+1;
      output;
   end;
   format Hosp_Admission_first mmddyy10.;
   drop t ;
run;
proc print data= timeline;  run;


*** Colorado - ALL Counties ***:
***-------------------------***;

*** Create local copy of COPHS data for Ethnicity = 'Hispanic or Latino' ***;
***----------------------------------------------------------------------***;

   %Let Grp_population = 1270060 ;      * <-- put population here **;


DATA COPHS_CY21; set COVID.COPHS_fix; 
   where Hosp_Admission ge '01JAN21'd   AND  Ethnicity = 'Hispanic or Latino';
   keep MR_Number  EventID   Hosp_Admission  county_of_residence   race   ethnicity    ICU_Admission  DOB  Positive_test  UTD  ChkCounty  ;
run;

/*   PROC contents data=COPHS_CY21 varnum ;  title1 'COPHS_CY21';  run;*/


** sort by MR_Number and create patient-level dataset   **;
  PROC sort data=COPHS_CY21  
             out= COPHS_CY21_sort; 
      by MR_Number Hosp_Admission ;
run;

**  Reduce dataset from admission level to patient level  **;
Data COPHS_CY21_patient; set COPHS_CY21_sort;
   by MR_Number;

   * count cases per reported date *;
   if first.MR_Number then DO;  NumHosp_perPat=0; Hosp_Admission_first = Hosp_Admission;  END;
   retain Hosp_Admission_first;
   NumHosp_perPat+1;

   IF last.MR_Number then DO;
      Hosp_Admission_last = Hosp_Admission;

      output;
   END;

   format Hosp_Admission_first  Hosp_Admission_last  mmddyy10.; 

* drop admission level variables  *;
   drop  Hosp_Admission   ;
run;


** sort by Hosp_Admission_first   **;
  PROC sort data=COPHS_CY21_patient  
             out= COPHS_CY21_date; 
      by Hosp_Admission_first ;
run;


**  Reduce dataset from patient level to date level **;
**  Result is one obs per date reported  **;
Data COPHS_CY21_rate; set COPHS_CY21_date;
   by Hosp_Admission_first;

* count cases per reported date *;
   if first.Hosp_Admission_first then NumHosp_perDay=0;
   NumHosp_perDay+1;

* calculate case rate  *;
   if last.Hosp_Admission_first then do;
      HospRate= NumHosp_perDay / (&Grp_population / 100000);
      output;
   end;

run;
/*   proc print data= COPHS_CY21_rate ;  ID Hosp_Admission_first ;  run;*/


      
** add ALL reported dates for populations with sparse data **;
Data COPHS_CY21_dates;  length county_of_residence $ 13  ;  merge Timeline  COPHS_CY21_rate;
   by Hosp_Admission_first;

* backfill missing with 0 *; 
   if NumHosp_perDay=. then NumHosp_perDay=0 ; 

   if HospRate = . then HospRate = 0 ; 

*add vars to describe population (which will be missing for obs from Timeline only) *;
      county_of_residence='ALL counties';  Race_Ethnic='Hispanic, all races';
run;


**  Calculate 7-day moving averages  **;
   PROC expand data=COPHS_CY21_dates   out=CO_H_MovingAverage  method=none;
      id Hosp_Admission_first;
      convert NumHosp_perDay=NumHosp7dAv / transformout=(movave 7);
      convert HospRate=Hosp7dAv / transformout=(movave 7);
run;

   PROC contents data=CO_H_MovingAverage varnum ;  title1 'CO_H_MovingAverage';  run;


* delete temp datasets not needed *;
proc datasets library=work NOlist ;
   delete  COPHS_CY21   COPHS_CY21_sort   COPHS_CY21_patient   COPHS_CY21_date   COPHS_CY21_rate   COPHS_CY21_dates  ;
quit;
run;





