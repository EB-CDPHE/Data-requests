

*** Create example dataset ***;
***------------------------***;

DATA Casetest;
   input Profile Address $  CaseDate  AgeGroup $  AG $ ;
   datalines;
   1  A 22000 Adult  A
   2  B 22001 Adult  A
   3  B 22005 Adult  A
   18 B 22115 Teen   T
   4  C 22012 Adult  A
   5  C 22017 Teen   T 
   6  D 22025 Kid    K 
   7  D 22033 Adult  A
   8  D 22035 Adult  A
   9  E 22100 Infant I
   10 E 22101 Kid    K
   11 E 22102 Teen   T
   12 E 22103 Adult  A
   13 E 22103 Adult  A
   14 F 22022 Adult  A
   15 F 22027 Teen   T
   16 F 22122 Kid    K
   17 F 22127 Adult  A
   ;
   format AG $1.;
run;
   proc print data=Casetest; id profile; format CaseDate mmddyy10. ; run;



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

   if first.Address then do;  NumDays_between_HHcases=.;  end;

   If month(CaseDate) in (3,4) then Timeperiod=1; else if month(caseDate) in (7) then Timeperiod=2;

run;
   proc print data= ExcludeLarge;  id profile;  format CaseDate mmddyy10. ;  run;



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

* transpose AG *;
   PROC transpose data=ExcludeLarge  
   out=WideDSN1b(drop= _NAME_)  
      prefix=AG ; 
      var AG;        
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
DATA HHwide; merge WideDSN1  WideDSN1b  WideDSN2 LastCase;
   by address;
   AG=cat(AG1, AG2, AG3);
   DROP AG1-AG3;
run;
   proc print data=HHwide;  id address;  
format CaseDate1-CaseDate3 monyy5.;  run;



*** Analysis ***;
proc freq data=HHwide ;
tables AgeGroup1 * AgeGroup2 * AgeGroup3 / list missing missprint ;
by TimePeriod;
run;
