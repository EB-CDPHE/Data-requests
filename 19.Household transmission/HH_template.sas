

*** Create example dataset ***;
***------------------------***;

DATA Casetest;
   input Profile Address $  CaseDate  AgeGroup $ ;
   datalines;
   1  A 22000 Adult
   2  B 22001 Adult
   3  B 22005 Adult
   4  C 22012 Adult
   5  C 22017 Teen 
   6  D 22025 Kid  
   7  D 22033 Adult
   8  D 22035 Adult
   9  E 22100 Toddler
   10 E 22101 Kid
   11 E 22102 Teen
   12 E 22103 Adult
   13 E 22103 Adult
   ;
run;
/*   proc print data=Casetest; id profile; format CaseDate mmddyy10. ; run;*/



*** Count Number cases per HH and restrict to HH with 2+ cases ***;
***------------------------------------------------------------***;

   proc sort data= Casetest
               out= CaseSort;
      by Address;

Data HHtest FlagAddress(keep=Address); set CaseSort;
  by Address;

  if first.Address then do; NumCaseperHH=0;  end;

  NumCaseperHH+1;
  NumDays_between_HHcases = CaseDate - lag(CaseDate);

  if last.Address then do;
    if NumCaseperHH=1 then delete;
    if NumCaseperHH>3 then output FlagAddress;
  end;

  output HHtest;
run;
/*   proc print data=FlagAddress; run;*/
   proc print data= HHtest;  id profile;  format CaseDate mmddyy10. ;  run;



*** Then remove HH with more than 10 cases ***;
***----------------------------------------***;

Data ExcludeLarge; merge FlagAddress(in=x)  HHtest ;
   by address;
   if x=1 then delete;
run;
/*   proc print data= ExcludeLarge;  id profile;  format CaseDate mmddyy10. ;  run;*/



*** Transpose data from Case level (tall) to HH level (wide) ***;
***----------------------------------------------------------***;

* transpose AgeGroup *;
   PROC transpose data=ExcludeLarge  
   out=WideDSN1(drop= _NAME_)  
      prefix=AgeGroup ; 

      var AgeGroup;        
      by address;  
run;
/*   proc print data= WideDSN1; run;*/

* transpose Dates *;
   PROC transpose data=ExcludeLarge  
   out=WideDSN2(drop= _NAME_)
      prefix=CaseDate ; 

      var CaseDate;          
      by address;  
run;
/*   proc print data= WideDSN2; format CaseDate1-CaseDate3 mmddyy10.; run;*/

* pull out final counter of number of cases per HH *;
Data LastCase(keep=Address  NumCaseperHH); set ExcludeLarge;
   by address;
   if last.address;
run;
/*   proc print data= LastCase; run;*/

* Merge transposed datasets and final counter together *;
DATA HHwide; merge WideDSN1 WideDSN2 LastCase;
   by address;

   TimePeriod=month(CaseDate1);
run;
/*   proc print data=HHwide;  id address;  format CaseDate1-CaseDate3 mmddyy10.;  run;*/



*** Analysis ***;
proc freq data=HHwide ;
tables AgeGroup1 * AgeGroup2 * AgeGroup3 / list missing missprint ;
by TimePeriod;
run;
