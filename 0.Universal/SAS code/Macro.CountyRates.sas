/**********************************************************************************************
PROGRAM:  macro.CountyRates
AUTHOR:	 Eric Bush
CREATED:	 September 21, 2021
MODIFIED: 102221:  Add 14d moving average calculation
          102121:  Add Mortality rate calculation	
***********************************************************************************************/

                                                    /*--------------------*
                                                     | CountyRates Macro  |
*-------------------------------------------------------------------------*
| PURPOSE: Calculate County-specific rates for cases, hosp, COPHS hops    |
|                                                                         |
| Defines macro variable:                                                 |
|     &COcnty  -->  county name                                           |
|     &County_Name -->  county name for use in DATA step                  |
|                                                                         |
| What this macro does:                                                   |
|  a) Create macro variable for county specific population data           |
|  b) Create age specific dataset and sort by date                        |
|  c) Reduce dataset from patient level to date level (obs=reported date) |
|     - count cases per reported date                                     |
|     - calculate case rate                                               |
|     - drop patient level variables                                      |
|  d) add ALL reported dates for populations with sparse data             |
|     - backfill missing caserate data with 0's                           |
|     - add vars to describe population                                   |
|  f) Calculate 7-day moving averages                                     |
|  g) delete temporary datasets created by macro that are not needed      |
*-------------------------------------------------------------------------*/

/*** NOTE:  based on using COVID.County_Population;*/


%Macro CountyRates(CountyName);

   * Add underscore to two part county names for use in DATA step statements *;
   data _null_;  set COVID.County_Population; 
      where County = "&CountyName" ;

      IF County in ("CLEAR CREEK", "EL PASO", "KIT CARSON", "LA PLATA", "LAS ANIMAS", "RIO BLANCO", "RIO GRANDE", "SAN JUAN", "SAN MIGUEL") 
      THEN DO;
         Cnty1= scan("&CountyName",1,' ');   
         Cnty2= scan("&CountyName",2,' ');   
         Cnty_Name= CATS(Cnty1, '_', Cnty2);
      END;
      ELSE  Cnty_Name= "&CountyName" ;
   
      call symputx("County_Name", Cnty_Name);    
   run;

   ** Create macro variable for age specific county population data **;
   data _null_; set COVID.County_Population; 
      where County = "&CountyName" ;

      call symputx("CntyPop", population);    * <-- put number from county population into macro variable;
   run;

   * Create County specific dataset *;
   DATA CEDRS_&County_Name;  set CEDRS_view_fix;
     where County = "&CountyName";   
   run;
   **  sort by date  **;
    PROC sort data= CEDRS_&County_Name  
               out= &County_Name._sort; 
      by ReportedDate;
   run;

   **  Reduce dataset from patient level to date level (one obs per date reported)  **;
   Data &County_Name._rate; set &County_Name._sort;
     by ReportedDate;

   * count cases per reported date *;
      if first.ReportedDate then DO;  NumCases=0;  NumHosp=0;  NumCOPHS=0; NumDied=0; NumDead=0;  END;
      NumCases+1;
      NumHosp+hospitalized;
      NumCOPHS+hospitalized_cophs;
      if outcome='Patient died' then NumDied+1;
      if DeathDueTo_vs_u071 = 1 then NumDead+1;

   * calculate case rate  *;
     if last.ReportedDate then do;
        CaseRate= NumCases / (&CntyPop/100000);
        HospRate= NumHosp / (&CntyPop/100000);
        COPHSRate= NumCOPHS / (&CntyPop/100000);
        DiedRate= NumDied / (&CntyPop/100000);
        MortRate= NumDead / (&CntyPop/100000);
        output;
     end;

   * drop patient level variables  *;
/*   drop ProfileID  EventID  Age_at_Reported  hospitalized  hospitalized_cophs   ;*/

   * keep only date level variables since Patient-level variables no longer have meaning  *;
   keep  NumCases  NumHosp   NumCOPHS   NumDied   NumDead
         CaseRate  HospRate  COPHSRate  DiedRate  MortRate  ReportedDate ;
   run;

** add ALL reported dates for populations with sparse data **;
Data &County_Name._dates; length  County $ 13  ;  merge Timeline  &County_Name._rate;
   by ReportedDate;

* backfill missing with 0 *; 
   if NumCases=. then NumCases=0 ; 
   if NumHosp=. then NumHosp=0 ; 
   if NumCOPHS=. then NumCOPHS=0 ; 
   if NumDied=. then NumDied=0 ; 
   if NumDead=. then NumDead=0 ; 

   if CaseRate=. then CaseRate=0 ; 
   if HospRate=. then HospRate=0 ; 
   if COPHSRate=. then COPHSRate=0 ; 
   if DiedRate=. then DiedRate=0 ; 
   if MortRate=. then MortRate=0 ; 

*add vars to describe population (will be missing for obs from Timeline only) *;
   County="&CountyName";  

run;

**  Calculate 7-day moving averages  **;
   PROC expand data=&County_Name._dates   out=&County_Name._movavg  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
      convert HospRate=Hosp7dAv / transformout=(movave 7);
      convert COPHSRate=COPHS7dAv / transformout=(movave 7);
      convert DiedRate=Died7dAv / transformout=(movave 7);
      convert MortRate=Mort7dAv / transformout=(movave 7);

**  Calculate 14-day moving averages  **;
/*   PROC expand data=&County_Name._dates   out=&County_Name._movavg  method=none;*/
/*      id ReportedDate;*/
/*      convert NumCases=Cases14dAv / transformout=(movave 14);*/
/*      convert CaseRate=Rates14dAv / transformout=(movave 14);*/
/*      convert HospRate=Hosp14dAv / transformout=(movave 14);*/
/*      convert COPHSRate=COPHS14dAv / transformout=(movave 14);*/
/*      convert DiedRate=Died14dAv / transformout=(movave 14);*/
/*      convert MortRate=Mort14dAv / transformout=(movave 14);*/
/*run;*/

* delete temp datasets not needed *;
proc datasets library=work NOlist ;
   delete  CEDRS_&County_Name   &County_Name._sort   &County_Name._rate   &County_Name._dates  ;
run;

%mend;


