
title; run;

proc contents data= COVID.CEDRS_view_fix  varnum ; run;




proc sort data = COVID.CEDRS_view_fix 
            out= CEDRS_key(keep=EventID ProfileID ReportedDate CollectionDate County);
   by EventID ;
run;



   PROC sort data= Lab_TT229_fix
               out= TT229_fix;
      by EventID LabSpecimenID ;
run;

Data CASES_w_PCR;
   merge  TT229_fix  CEDRS_key(in=c);
   by EventID;

   if c;
run;

/**/
/*proc print data= Lab_TT229_fix; where EventID='1000006'; run;*/
/**/
/*   PROC freq data = Lab_TT229_fix  ;*/
/*      tables  EventID / out=EventID_TT229_Count ; run;*/
/*   PROC freq data = EventID_TT229_Count;*/
/*      tables COUNT;*/
/*run;*/

proc contents data= CASES_w_PCR  varnum ; run;

   PROC means data= CASES_w_PCR  n nmiss;
      where ResultID_TT229 ne .;
/*      var LabSpecimenID;*/
      var ReportedDate;

run;


   PROC freq data= CASES_w_PCR;
      tables ResultID_TT229 / missing missprint ;
run;

   PROC SQL;
      select count(distinct EventID) as NumPeople
      from CASES_w_PCR 
      where ResultID_TT229 ne .
      group ResultID_TT229;
run;





