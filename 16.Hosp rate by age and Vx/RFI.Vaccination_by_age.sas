/**********************************************************************************************
PROGRAM:  RFI.Vaccination_by_age.sas
AUTHOR:   Eric Bush
CREATED:  October 22, 2021
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

title;  options pageno=1;


*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA CEDRS_fix;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  ReportedDate ge '01JAN21'd ;
   Keep  ProfileID EventID  CountyAssigned  County  CaseStatus  Hospitalized  Outcome Gender 
         Age_Group  Age_at_Reported  Vax_UTD  Vax_FirstDose  Vaccine_Received  BreakThrough  
         ReportedDate ;  
run;

   PROC contents data=CEDRS_fix  varnum; title1 'CEDRS_CY21'; run;



***  Check data  ***;
***--------------***;

** Age vars **;
   PROC means data=CEDRS_fix  n nmiss  ;
      var  Age_at_Reported  Age_Years ;
run;

   PROC FREQ data=CEDRS_fix   ;
      tables  Age_Group;
run;

   PROC format;
      value AgeFmt
         0-<5 = '0-4'
         5-<12= '5-11'
         12-<16 = '12-15'
         16-<18 = '16-17'
         18-<30 = '18-29'
         30-<50 = '30-49'
         50-<65 = '50-64'
         65-115 = '65+' ;
run;

   PROC FREQ data=CEDRS_fix   ;
      tables  Age_at_Reported ;
      format  Age_at_Reported AgeFmt.;
run;
   proc means data=CEDRS_fix  min max; 
      var Age_Years;
      class Age_at_Reported ;
      format  Age_at_Reported AgeFmt.;
run;


** Date vars **;
   PROC means data=CEDRS_fix  n nmiss  ;
      var  ReportedDate  Vax_UTD  Vax_FirstDose ;
run;
   PROC FREQ data=CEDRS_fix   ;
      tables  Vax_UTD Vax_FirstDose ;
      format Vax_UTD Vax_FirstDose monyy.;
run;


*** County Population data ***;
***------------------------***;

   PROC contents data=COVID.County_Population;  title1 'COVID.County_Population';  run;

   PROC print data= COVID.County_Population; id county; run;



*** Create timeline of all dates ***;
***------------------------------***;

DATA timeline;
   ReportedDate='01JAN21'd;
   output;
   do t = 1 to 272;
      ReportedDate+1;
      output;
   end;
   format ReportedDate mmddyy10.;
   drop t ;
run;
proc print data= timeline;  run;







***  Access population data  ***;
***--------------------------***;

*** Obtain county population data for specified age groups ***;
***--------------------------------------------------------***;

/*_________________________________________________________________________________________*
 | For 2019 county level population data BY AGE GROUPS:
 |-----------------------------------------------------------------------------------------*
 | SOURCE:  https://demography.dola.colorado.gov/population/data/sya-county/  
 | STEPS:
 |  1) define age group intervals (e.g. 0-5,  6-11,  12-17, and 18-121) for ALL counties
 |  2) download csv, clean up file, and save Excel workbook (xlsx) as CntyPopAge.xlsx 
 *-----------------------------------------------------------------------------------------*/

** Create libname with XLSX engine that points to XLSX file **;
libname mysheets xlsx 'C:\Users\eabush\Documents\CDPHE\Requests\data\Pediatric pop by county.xlsx' ;

** see contents of libref - one dataset for each tab of the spreadsheet **;
   PROC contents data=mysheets._all_ ; title1; run;

** print tabs from spreadsheet **;
   proc print data=mysheets.data; run;

**  Sort by county and transpose pop data by age groups  **;
   proc sort data=mysheets.data(keep=County Age Total)  out=CntyPopAge; by County; 
   PROC transpose data= CntyPopAge  out=CountyPopbyAge;
      by County;
      id Age;
      var Total;
run;
/*   proc print data= CountyPopbyAge; run;*/

**  Define age population variables  **;
DATA CountyPop_est ; 
   length County $ 11;
   set CountyPopbyAge(rename=(County=tmp_county)) ;

   County=upcase(tmp_county);
   format County $11.;
     Yrs0_5 = input(compress(_0_to_5,','), best12.) ;
    Yrs6_11 = input(compress(_6_to_11,','), best12.) ;
   Yrs12_17 = input(compress(_12_to_17,','), best12.) ;
  Yrs18_121 = input(compress(_18_to_121, ','), best12.) ;
   County_population_est = Yrs0_5 +  Yrs6_11  +  Yrs12_17  +  Yrs18_121;
   Label
        Yrs0_5    = 'Population for 0-5 year olds'
       Yrs6_11    = 'Population for 6-11 year olds'
      Yrs12_17    = 'Population for 12-17 year olds'
     Yrs18_121  = 'Population for 18-121 year olds' ;
   drop _LABEL_  _NAME_  tmp_county  _0_to_5   _6_to_11   _12_to_17   _18_to_121   ;
run;
   PROC print data= CountyPop_est; run;



***  Create Age-specific dataset  ***;
***-------------------------------***;

%LET AgeLB = 0;   * will select obs GE than this number;
%LET AgeUB = 5;   * will select obs < than this number;


**  Create age specific dataset and sort by date  **;
 Data CEDRS_AG; set CEDRS_fix;
    if &AgeLB le  Age_at_Reported  < &AgeUB;
run;
   PROC sort data= CEDRS_AG  
              out= CEDRS_AG_sort; 
      by ReportedDate;
run;


**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data CEDRS_AG_rate; set CEDRS_AG_sort;
   by ReportedDate;

   * set accumulator vars to 0 for first ReportedDate in group *;
   if first.ReportedDate then DO;  
      NumCases_VxY=0;  NumHosp_VxY=0;  NumDeaths_VxY=0;  
      NumCases_VxN=0;  NumHosp_VxN=0;  NumDeaths_VxN=0;  
   END;

   * count daily cases (i.e. sum within ReportedDate group) *;
   if CaseStatus in('confirmed', 'probable') then do; if Vax_UTD ne . then NumCases_VxY+1; else NumCases_VxN+1;  end; 
   if hospitalized = 1 then do;  if Vax_UTD ne . then NumHosp_VxY+1; else NumHosp_VxN+1; end;
   if outcome = 'Patient died' then do;  if Vax_UTD ne . then NumDeaths_VxY+1;  else NumDeaths_VxN+1;  end; 

   * keep last ReportedDate in group (with daily totals) *;
   if last.ReportedDate then output;

   * drop patient level variables  *;
   keep ReportedDate  NumCases_VxY  NumCases_VxN  NumHosp_VxY  NumHosp_VxN  NumDeaths_VxY  NumDeaths_VxN ;

run;


** add ALL reported dates for populations with sparse data **;
Data CEDRS_AG_dates;  length AgeGroup $ 9 ;  merge Timeline  CEDRS_AG_rate;
   by ReportedDate;

   * backfill missing with 0 and add vars to describe population *;
   if NumCases_VxY=. then NumCases_VxY=0 ; 
   if NumCases_VxN=. then NumCases_VxN=0 ; 

   if NumHosp_VxY=.  then NumHosp_VxY=0 ; 
   if NumHosp_VxN=.  then NumHosp_VxN=0 ; 

   if NumDeaths_VxY=. then NumDeaths_VxY=0 ; 
   if NumDeaths_VxN=. then NumDeaths_VxN=0 ; 

   * create total vars *;
/*   TotalCases = NumProbable + NumConfirmed ;*/
/*   TotalDead = NumProbDead + NumConfDead ;*/

*add vars to describe population *;
   AgeGroup="&AgeGrp";  format AgeGroup $9.;

run;



%Macro AgeGrpStats(AgeGrp, AgeLB, AgeUB);

** Create macro variable for age specific county population data **;
data _null_; set CountyPop_est; where County = "&COcnty" ;
   call symputx("agepopulation", &AgeGrp);    * <-- put number from county population into macro variable;
run;

**  Create age specific dataset and sort by date  **;
 Data &County_Name; set CEDRS_&County_Name;
    if &AgeLB le  Age_at_Reported  < &AgeUB;
run;
   PROC sort data= &County_Name  
              out= &County_Name._sort; 
      by ReportedDate;
run;

**  Reduce dataset from patient level to date level (one obs per date reported)  **;
Data &County_Name._rate; set &County_Name._sort;
   by ReportedDate;

* count cases per reported date *;
   if first.ReportedDate then NumCases=0;
   NumCases+1;
* calculate case rate  *;
   if last.ReportedDate then do;
      CaseRate= NumCases / (&agepopulation/100000);
      output;
   end;
* drop patient level variables  *;
   drop ProfileID  EventID  Age_at_Reported  County;
run;

** add ALL reported dates for populations with sparse data **;
Data &County_Name._dates; length Ages $ 9  County $ 13  ;  merge Timeline  &County_Name._rate;
   by ReportedDate;

* backfill missing with 0 *; 
   if NumCases=. then NumCases=0 ; 
   if CaseRate=. then CaseRate=0 ; 

*add vars to describe population *;
   County="&COcnty";  
   Ages="&AgeGrp";  format Ages $9.;

run;

**  Calculate 7-day moving averages  **;
   PROC expand data=&County_Name._dates   out=&County_Name._&AgeGrp  method=none;
      id ReportedDate;
      convert NumCases=Cases7dAv / transformout=(movave 7);
      convert CaseRate=Rates7dAv / transformout=(movave 7);
run;

* delete temp datasets not needed *;
proc datasets library=work NOlist ;
   delete &COcnty   &COcnty._rate   &COcnty._sort   &COcnty._dates  ;
run;

%mend;


