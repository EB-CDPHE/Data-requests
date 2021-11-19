

*** Create example dataset ***;
***------------------------***;

DATA Casetest;
   input Profile Address $  CaseDate  AgeGroup $  AG $  ;
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
   19 G 22010 Adult  A
   20 G 22020 Adult  A
   21 G 22030 Adult  A
   22 G 22040 Adult  A
   23 G 22050 Adult  A
   24 G 22060 Adult  A
;
run;
   proc print data=Casetest; id profile; format CaseDate mmddyy10. ; run;



*** Count Number cases per HH and restrict to HH with 2+ cases ***;
***------------------------------------------------------------***;
   proc sort data= Casetest
               out= CaseSort;
      by Address CaseDate;

Data HHtest FlagAddress(keep=Address); set CaseSort;
   by Address;

   if first.Address then do; NumCaseperHH=0;  Cluster=1;  ClusterCase=0;  Days_between_cases=0;  end;
   else Days_between_cases = CaseDate - lag(CaseDate);

   NumCaseperHH+1;

   if Days_between_cases>3 then do;  Cluster+1; ClusterCase=0;  Days_between_cases=0;  end; 

   ClusterCase+1;
   Days_between_cases = CaseDate - lag(CaseDate);

  if last.Address then do;
    if NumCaseperHH=1 then delete;
    if NumCaseperHH>5 then output FlagAddress;
  end;

  output HHtest;
run;
/*   proc print data=FlagAddress; run;*/
/*   proc print data= HHtest;  id address; by address;  format CaseDate mmddyy10. ;  run;*/


*** Then remove HH with more than 10 cases ***;
***----------------------------------------***;
Data ExcludeLarge; merge FlagAddress(in=x)  HHtest ;
   by address;
   if x=1 then delete;

   if ClusterCase=1 then Days_between_cases=0;
run;
/*   proc print data= ExcludeLarge;  id address; by address; format CaseDate  mmddyy10. ;  run;*/


*** Transpose data from Case level (tall) to HH level (wide) ***;
***----------------------------------------------------------***;

* transpose Dates *;
   PROC transpose data=ExcludeLarge  
   out=WideDSN1(drop= _NAME_)
      prefix=CaseDate ; 
      var CaseDate;          
      by address cluster;  
run;
/*   proc print data= WideDSN1; format CaseDate1-CaseDate3 mmddyy10.; run;*/

* transpose AG *;
   PROC transpose data=ExcludeLarge  
   out=WideDSN2(drop= _NAME_)  
      prefix=AG ; 
      var AG;        
      by address cluster;  
run;
/*   proc print data= WideDSN2; run;*/

* transpose DaysBetween *;
   PROC transpose data=ExcludeLarge  
   out=WideDSN4(drop= _NAME_)
      prefix=DaysBetween ; 
      var Days_between_cases;          
      by address cluster;  
run;
/*   proc print data= WideDSN4;  run;*/


* Merge transposed datasets and final counter together *;
DATA ClusterWide; merge  WideDSN1  WideDSN2    WideDSN4 ;
   by address cluster;  

   array CDs{5} CaseDate1-CaseDate5;
   array AGs{5} AG1-AG5;
   do i = 1 to 5;
      if month(CDs{i}) in (3,4) then AGs{i}=lowcase(AGs{i});
      else if month(CDs{i}) in (7) then AGs{i}=upcase(AGs{i});
   end;

   AG = cats(AG1, AG2, AG3, AG4, AG5);
/*   TP1_AG=compress(AG,'IKTA');*/
/*   TP2_AG=compress(AG,'ikta');*/

   DROP AG1-AG5  i ;

* ADD variables to use in analysis *;
   NumCases1=COUNTC(AG,'ikta') ;
   NumCases2=COUNTC(AG,'IKTA') ;
   NumCases = NumCases1 + NumCases2 ;

run;

   proc print data= ClusterWide; id address ; by address; 
      var Cluster CaseDate1  CaseDate2 AG  NumCases1 NumCases2  NumCases  DaysBetween1  DaysBetween2  ;
      format CaseDate1-CaseDate5 monyy5.;  
run;



*** Analysis ***;
***----------***;

** Number of HH with 1+ case in time period 1, 2, and 1&2. **;
   PROC SQL;
      select count(distinct Address) as NumHH20
      from ClusterWide 
      where NumCases1>0 ;
run;

   PROC SQL;
      select count(distinct Address) as NumHH21
      from ClusterWide 
      where NumCases2>0 ;
run;

   PROC SQL;
      select count(distinct Address) as NumHH
      from ClusterWide ;
run;


** Number of clusters by time period **;
   PROC means data=ClusterWide n ;  where NumCases1>0;   var  Cluster NumCases1 ; run;
   PROC means data=ClusterWide n ;  where NumCases2>0;   var  Cluster NumCases2;  run;
   PROC means data=ClusterWide n ;  where NumCases >0;   var  Cluster NumCases ;  run;


 ** Number of clusters per HH by time period **;
   proc freq data=clusterwide noprint ; 
      where month(CaseDate1) in (3,4);
      tables Address  / out=ClusterPerHH1;
/*   proc print data= ClusterPerHH1; run;*/
   proc freq data= ClusterPerHH1; tables Count; run;

   proc freq data=clusterwide noprint ; 
      where month(CaseDate1) in (7,8);
      tables Address  / out=ClusterPerHH2;
   proc freq data= ClusterPerHH2; tables Count; run;

   proc freq data=clusterwide noprint ; 
      tables Address  / out=ClusterPerHH;
   proc freq data= ClusterPerHH; tables Count; run;


** Distribution of FULL AG's involved in time period 1, 2, and 1&2 **;
   PROC freq data=clusterwide ;
      where month(CaseDate1) in (3,4);  
      tables AG    /  missing missprint ;
run;
   PROC freq data=clusterwide ;
      where month(CaseDate1) in (7,8);  
      tables AG    /  missing missprint ;
run;


** Distribution of FIRST CASE per AG's involved in time period 1, 2, and 1&2 **;
   PROC freq data=clusterwide ;
      where month(CaseDate1) in (3,4);  
      tables AG    /  missing missprint ;
      format AG $1.;
run;
   PROC freq data=clusterwide ;
      where month(CaseDate1) in (7,8);  
      tables AG    /  missing missprint ;
      format AG $1.;
run;


** FOR THOSE HH WITH A CASE DURING TP:  Distribution of which AG was first case in time period 1, 2, and 1&2 **;
   PROC freq data=clusterwide ;
      where month(CaseDate1) in (3,4)  AND  NumCases1>0;
      tables AG   /  missing missprint ;
      format AG $1.;
run;
   PROC freq data=clusterwide ;
      where month(CaseDate1) in (7,8)  AND  NumCases2>0;
      tables AG   /  missing missprint ;
      format AG $1.;
run;





** Average number of days between HH cases by time period **;


