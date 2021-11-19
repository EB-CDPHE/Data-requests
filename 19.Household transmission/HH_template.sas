

*** Create example dataset ***;
***------------------------***;

DATA Casetest;
   input Profile Address $  CaseDate  AgeGroup $  AG $ Diff ;
   datalines;
   1  A 22000 Adult  A 8
   2  B 22001 Adult  A 6
   3  B 22005 Adult  A 2
   18 B 22115 Teen   T 4
   4  C 22012 Adult  A 1
   5  C 22017 Teen   T 3
   6  D 22025 Kid    K 2
   7  D 22033 Adult  A 5
   8  D 22035 Adult  A 7
   9  E 22100 Infant I 9
   10 E 22101 Kid    K 8
   11 E 22102 Teen   T 5
   12 E 22103 Adult  A 4
   13 E 22103 Adult  A 6
   14 F 22022 Adult  A 3
   15 F 22027 Teen   T 1
   16 F 22122 Kid    K 2
   17 F 22127 Adult  A 3
   19 G 22010 Adult  A 4
   20 G 22020 Adult  A 5
   21 G 22030 Adult  A 6
   22 G 22040 Adult  A 7
   23 G 22050 Adult  A 8
   24 G 22060 Adult  A 9
;
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

  if month(CaseDate) in (3,4) then CaseDate1=CaseDate; else
  if month(CaseDate) in (7,8) then CaseDate2=CaseDate; 

  NumDays_between_HHcases1 = CaseDate1 - lag(CaseDate1);
  NumDays_between_HHcases2 = CaseDate2 - lag(CaseDate2);

  if last.Address then do;
    if NumCaseperHH=1 then delete;
    if NumCaseperHH>5 then output FlagAddress;
  end;

  output HHtest;
run;
/*   proc print data=FlagAddress; run;*/
   proc print data= HHtest;  id profile;  format CaseDate CaseDate1 CaseDate2 mmddyy10. ;  run;


*** Then remove HH with more than 10 cases ***;
***----------------------------------------***;
Data ExcludeLarge; merge FlagAddress(in=x)  HHtest ;
   by address;
   if x=1 then delete;

      if (CaseDate1 ne . and NumDays_between_HHcases1=.) then NumDays_between_HHcases1=0; 
      if (CaseDate2 ne . and NumDays_between_HHcases2=.) then NumDays_between_HHcases2=0; 

run;
   proc print data= ExcludeLarge;  id profile;  format CaseDate CaseDate1 CaseDate2 mmddyy10. ;  run;


*** Transpose data from Case level (tall) to HH level (wide) ***;
***----------------------------------------------------------***;

* transpose AgeGroup *;
/*   PROC transpose data=ExcludeLarge  */
/*   out=WideDSN1(drop= _NAME_)  */
/*      prefix=AgeGroup ; */
/*      var AgeGroup;        */
/*      by address;  */
/*run;*/
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

* transpose DaysBetween *;
   PROC transpose data=ExcludeLarge  
   out=WideDSN3(drop= _NAME_)
      prefix=DaysBetween ; 
      var NumDays_between_HHcases;          
      by address;  
run;
/*   proc print data= WideDSN3;  run;*/

* pull out final counter of number of cases per HH *;
Data LastCase(keep=Address  NumCaseperHH); set ExcludeLarge;
   by address;
   if last.address;
run;
/*   proc print data= LastCase; run;*/

* Merge transposed datasets and final counter together *;
DATA HHwideNEW; merge      WideDSN1b  WideDSN2  WideDSN3  LastCase;
   by address;

   array CDs{5} CaseDate1-CaseDate5;
   array AGs{5} AG1-AG5;
   do i = 1 to 5;
      if month(CDs{i}) in (3,4) then AGs{i}=lowcase(AGs{i});
      else if month(CDs{i}) in (7) then AGs{i}=upcase(AGs{i});
   end;

   AG = cats(AG1, AG2, AG3, AG4, AG5);
   TP1_AG=compress(AG,'IKTA');
   TP2_AG=compress(AG,'ikta');

   DROP AG1-AG5  i ;

* ADD variables to use in analysis *;
   NumHHcases1=COUNTC(AG,'ikta') ;
   NumHHcases2=COUNTC(AG,'IKTA') ;
   NumHHcases = NumHHcases1 + NumHHcases2;
run;
   proc print data=HHwideNEW;  
      id address;  
      var DaysBetween1 - DaysBetween5  TP1_AG  TP2_AG  AG  NumHHcases1  NumHHcases2 NumHHcases ;
/*      format CaseDate1-CaseDate5 monyy5.;  */
run;



*** Analysis ***;
***----------***;


** Number of HH with 1+ case in time period 1, 2, and 1&2. **;
   PROC means data=HHwideNEW n ;  where NumHHcases1>0;   var  NumHHcases1 ;  run;
   PROC means data=HHwideNEW n ;  where NumHHcases2>0;   var  NumHHcases2 ;  run;

** Distribution of the number of cases in a HH for time period 1, 2, and 1&2 (total). **;
   PROC freq data=HHwideNEW ;
      tables NumHHcases1  NumHHcases2  NumHHcases/  missing missprint ;
      tables NumHHcases1 * NumHHcases2  / list  missing missprint ;
run;


** Distribution of AG's involved in time period 1, 2, and 1&2 **;
   PROC freq data=HHwideNEW ;
      tables TP1_AG   TP2_AG  /  missing missprint ;
run;

** Distribution of which AG was first case in time period 1, 2, and 1&2 **;
   PROC freq data=HHwideNEW ;
      tables TP1_AG   TP2_AG  /  missing missprint ;
      format TP1_AG   TP2_AG $1.;
run;

** FOR THOSE HH WITH A CASE DURING TP:  Distribution of which AG was first case in time period 1, 2, and 1&2 **;
   PROC freq data=HHwideNEW ;
      where NumHHcases1>0;
      tables TP1_AG   /  missing missprint ;
      format TP1_AG   TP2_AG $1.;
run;
   PROC freq data=HHwideNEW ;
      where NumHHcases2>0;
      tables TP2_AG   /  missing missprint ;
      format TP1_AG   TP2_AG $1.;
run;




** Average number of days between HH cases by time period **;


