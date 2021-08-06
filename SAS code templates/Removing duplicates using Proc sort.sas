/*_________________________________________________*
| Removing duplicates using PROC sort
*__________________________________________________*/

/*-------------------------------------------------*
 | First pair - dup on one key only; not vars
 | Second pair - dup on two keys; not vars
 | Third pair - dup on all keys and vars
 | Fourth pair - no dup
 *-------------------------------------------------*/


Data DupDS ;
input key1 $ key2 $ var1 var2 ;
datalines;
Pair1 AA  1  2
Pair1 BB  3  4
Pair2 DD  5  6
Pair2 DD  7  8
Pair3 CC  9  0
Pair3 CC  9  0
Pair4 EE 11 12
Pair5 FF 13 14
;
run;
proc print data= DupDS; run;


*** Methods to de-dup the dataset ***;
***-------------------------------***;

**  Option 1  - De-dup based on 1 key  **;
   PROC sort data=DupDS  out=DS1  NODUPKEY  ;  
      by key1;
run;
   PROC print data= DS1;   title1 'De-dup key1';   run;


**  Option 2  - De-dup based on 2 keys  **;
   PROC sort data=DupDS  out=DS2  NODUPKEY  ;  
      by key1 key2 ;
run;
   PROC print data= DS2;   title1 'De-dup key2';   run;

**  Option 2b  - De-dup based on 2 vars (key and var)  **;
   PROC sort data=DupDS  out=DS2b  NODUPKEY  ;  
      by key1 var1 ;
run;
   PROC print data= DS2b;   title1 'De-dup key1 and var1';   run;

**  Option 3  - De-dup based on all vars  **;
   PROC sort data=DupDS  out=DS3  NODUPREC  ;  
      by key1  ;
run;
   PROC print data= DS3;   title1 'De-dup all vars';   run;









