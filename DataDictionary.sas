/*
 | Data dictionary 
 *-------------------*/

options ps=50 ls=90 ;     * Portrait pagesize settings for SAS font 10 pt *;

title1 'DPHE66';

options pageno=1;
   PROC contents data=CEDRS66.zDSI_Events  varnum ;  run;  


title1 'DPHE66.zDSI_Profiles';
options pageno=1;
      PROC contents data=CEDRS66.zDSI_Profiles  varnum ;  run;  


options pageno=1;
title1 'DPHE66.zDSI_LabTests';
      PROC contents data=CEDRS66.zDSI_LabTests  varnum ;  run;  






