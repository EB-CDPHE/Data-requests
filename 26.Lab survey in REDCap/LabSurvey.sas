/**********************************************************************************************
PROGRAM:  LabSurvey.sas
AUTHOR:   Eric Bush
CREATED:  April 28, 2022
MODIFIED: 	
PURPOSE:	 
INPUT:	      	  
OUTPUT:	 	
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;



** Create libname with XLSX engine that points to XLSX file **;
libname  RedCap   xlsx 'C:\Users\eabush\Documents\GitHub\Data-requests\26.Lab survey in REDCap\Data\SectionL_COVID_DATA_28APR22.xlsx'; run;

   proc contents data= RedCap.data  varnum ; run;

title1 '2022 Statewide Lab Survey';
title2 'Section L. COVID19';

** Create SAS dataset from spreadsheet **;
DATA L_Covid;   set RedCap.data;
run;

   proc contents data= L_Covid  varnum ; run;

*** Survey Response ***;

** Number of completed surveys **;
   PROC FREQ data= L_Covid;
      tables  l_covid19_complete ;
      tables  l_covid19_complete * anycovidtestingonsite  *  anycovidtestingoffsite / list  missing  missprint ;
run;
/*
FINDINGS:
 | n=94 records, of which n=34 are incomplete.
 | n=7 of the 34 incomplete records answered screeener questions
 | n=5 of those 7 indicated they did offsite testing and 2 only did onsite testing. 
*/

** Print responses to screener questions for the n=7 incomplete records **;
   PROC print data= L_Covid ;
      where l_covid19_complete=0  AND  anycovidtestingonsite ne .   ;
      id LabID;
      var anycovidtestingonsite   anycovidtestingoffsite  ;     * screener questions *;
/*      var  anycovidtestingoffsite  OffsiteHospLab  offsitephlab  offsitecommlab  offsiteotherlab  WeeksCOVIDtestingOffsite   ;     * offsite questions *;*/
      title3 'incomplete records with data';
run;

** Determine where the 5 incomplete records that did off-site testing dropped out of survey **;
   PROC print data= L_Covid ;
      where LabID in (23, 35, 81) ;
      id LabID;
/*      var  anycovidtestingoffsite   DateCOVIDtestingOnsite   TestType_PCR  TestType_OMA  TestType_Antigen  TestType_Serology  TestType_WGS  TestType_Other;*/
/*      var  Rpt_OMA_CDPHE   Rpt_OMA_LPHA  Rpt_OMA_Other  ;            *who report to*;*/
/*      var  Rpt_CDPHE_HL7 Rpt_CDPHE_MoveIT Rpt_CDPHE_flat  Rpt_CDPHE_portal  Rpt_CDPHE_email  Rpt_CDPHE_fax  Rpt_CDPHE_Other  ;  * how rpt to CDPHE *;*/
/*      var  Rpt_LPHA_email  Rpt_LPHA_fax  Rpt_LPHA_Other ;  * how rpt to LDPHA *;*/
/*      var  Cares_Act_aware  Cares_Act_comply ;  * last two questions; */
run;
/*
FINDINGS for the 5 incomplete records that did off-site testing:
 |    n=2 didn't answer any of the follow questions to off-site testing.
 |    n=1 didn't answer any further questions
 |    n=1 answered item 7 (DateCOVIDtestingOnsite) but no further questions.
 |    n=1 answered all questions in the survey.  KEEP this record. Don't know why it is considered incomplete. 
*/



DATA L_complete;   set L_Covid;
   where (l_covid19_complete = 2)  AND  (anycovidtestingonsite =1 OR  anycovidtestingoffsite =1  OR  LabID=81 );
run;

*** Survey Screeners ***;
   PROC FREQ data= L_complete;
      tables  anycovidtestingonsite * anycovidtestingoffsite  ;
run;


*** Off-site Testing ***;
   PROC FREQ data= L_complete;
      tables  anycovidtestingoffsite  ;
run;

   PROC FREQ data= L_complete;
      where  anycovidtestingoffsite =1 ;
      tables  OffsiteHospLab  offsitephlab  offsitecommlab  offsiteotherlab  ;

run;
