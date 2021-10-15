/**********************************************************************************************
PROGRAM:    Key_Merge.COPHS.CEDRS      
AUTHOR:		Eric Bush
CREATED:	   July 5, 2021
MODIFIED:   
PURPOSE:	   Connect to dphe144 "CEDRS_view" and create associated SAS dataset
INPUT:		dbo66.Profiles   COVID.COPHS_fix   MMWR_cases
OUTPUT:		ICU_Key --> MMWR_ICU
***********************************************************************************************/

***  Create key from CEDRS66.Profiles   ***;
***_____________________________________***;

LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;        

DATA Profiles; set CEDRS66.Profiles;    
  if Birthdate ne ''   AND   LastName ne ''   AND    FirstName  ne ''   ; 
  keep ProfileID LastName FirstName BirthDate ;
run;
   PROC contents data=Profiles  varnum ;  run;    


   proc sort data=Profiles out=Profiles_sort; by BirthDate LastName FirstName ;  run;
DATA Profiles_key;   
   length COPHS_ID $ 100   ProfileID $ 15;  
   set Profiles_sort(rename=(ProfileID=tmp_ProfileID));  

   COPHS_ID = catx(":", Birthdate, propcase(LastName), propcase(FirstName) );
   ProfileID = cats(tmp_ProfileID);
   format  COPHS_ID  $100.  ProfileID $15.;
   keep COPHS_ID  ProfileID;
run; 
/*   PROC contents data=Profiles_key  ; run;*/
/*   PROC print data=Profiles_key;  id COPHS_ID;  run;*/


***  Create key from COVID.COPHS_fix   ***;
***____________________________________***;

   PROC sort  data= COVID.COPHS_fix(keep=DOB Last_Name First_Name ICU_Admission)  out=COPHS_sort; 
      by DOB Last_Name First_Name ;
DATA COPHS_key;   
   length COPHS_ID $ 100;   
   set COPHS_sort;

   DOB_char=put(DOB, yymmdd10.);
   COPHS_ID = catx(":", DOB_char, propcase(Last_Name), propcase(First_Name));
   format  COPHS_ID  $100.;
   keep COPHS_ID  ICU_Admission;
run;
/*   PROC contents data=COPHS_key ; run;*/
/*   PROC print data= COPHS_key; id COPHS_ID; run;*/


***  Create ICU key merge of Profiles_key AND COPHS_key   ***;
***_______________________________________________________***;

   proc sort data=COPHS_key    out=C_key; by COPHS_ID;
   proc sort data=Profiles_key out=P_key; by COPHS_ID;
DATA ICU_Key; merge C_key(in=c)  P_key(in=p) ;
   by COPHS_ID; 
   if c=1 and p=1;
run;
   PROC contents data=ICU_Key  varnum; run;
/*   PROC print data=ICU_Key; id COPHS_ID; run;*/


***  Merge ICU key with MMWRcases data   ***;
***______________________________________***;

DATA MMWR_key;  
   length  ProfileID $ 15;   
   set  MMWR_cases;

   format  ProfileID $15.;
   keep ProfileID County Age_Years hospitalized ; 
run;
   PROC contents data=MMWR_key  varnum ; run;
 

   proc sort data=ICU_Key  out=I_key; by ProfileID;
   proc sort data=MMWR_key out=M_key; by ProfileID;
DATA MMWR_ICU; merge I_key(in=i)  M_key(in=m) ;
   by ProfileID; 
   if i=1 AND m=1;
   if ICU_Admission ne . then ICU=1; else ICU=0;
run;
/*   PROC print data=MMWR_ICU ; id ProfileID; run;*/

** Contents for final dataset for estimation **;
   PROC contents data=MMWR_ICU  varnum ; run;


