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

** Determine where the 5 incomplete records that did off-site testing (as well as on-site testing) dropped out of survey **;
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


** Determine where the 2 incomplete records that did ONLY on-site testing dropped out of survey **;
   PROC print data= L_Covid ;
      where l_covid19_complete=0   AND  anycovidtestingonsite=1  AND  anycovidtestingoffsite=0 ;
      id LabID;
      var  anycovidtestingonsite  anycovidtestingoffsite   DateCOVIDtestingOnsite   TestType_PCR  TestType_OMA  TestType_Antigen  TestType_Serology  TestType_WGS  TestType_Other;
/*      var  Rpt_OMA_CDPHE   Rpt_OMA_LPHA  Rpt_OMA_Other  ;            *who report to*;*/
/*      var  Rpt_CDPHE_HL7 Rpt_CDPHE_MoveIT Rpt_CDPHE_flat  Rpt_CDPHE_portal  Rpt_CDPHE_email  Rpt_CDPHE_fax  Rpt_CDPHE_Other  ;  * how rpt to CDPHE *;*/
/*      var  Rpt_LPHA_email  Rpt_LPHA_fax  Rpt_LPHA_Other ;  * how rpt to LDPHA *;*/
/*      var  Cares_Act_aware  Cares_Act_comply ;  * last two questions; */
run;
/*
FINDINGS for the 2 incomplete records that did on-site testing only:
Neither answered any questions beyond the two screener questions.
*/



DATA L_complete;   set L_Covid;
   where (l_covid19_complete = 2)  AND  (anycovidtestingonsite =1 OR  anycovidtestingoffsite =1  OR  LabID=81 );

   NumOffSiteLabs = sum(OffsiteHospLab,  offsitephlab,  offsitecommlab,  offsiteotherlab);
   Label NumOffSiteLabs = 'Number of types of off-site labs used';

   NumPlatforms = sum(TestType_PCR,  TestType_OMA,  TestType_Antigen,  TestType_Serology, TestType_WGS);
   Label NumPlatforms = 'Number of testing platforms Labs used on-site';
        
   if offsiteotherlab = . then offsiteotherlab = 0;
run;


***  On-site and Off-site COVID testing by Labs  ***;
***----------------------------------------------***;

   PROC FREQ data= L_complete;
      tables  AnyCovidTestingOnsite * anycovidtestingoffsite  ;
run;
/*______________________________________________________*
 FINDINGS:
  n=52 good surveys (as of 4/28)
    n=2 did off-site testing only
    n=50 did on-site testing; 
      n=12 did on-site testing only 
      n=38 did both on-site and off-site testing
 *______________________________________________________*/


*** Off-site Testing - Types of Labs used ***;
***---------------------------------------***;

   PROC FREQ data= L_complete;
      tables  anycovidtestingoffsite  NumOffSiteLabs ;
run;

   PROC FREQ data= L_complete ;
      where  anycovidtestingoffsite =1 ;
      tables OffsiteHospLab * offsitephlab * offsitecommlab * offsiteotherlab / list  missing  missprint ;
run;
/*____________________________________________________________________________________________*
 FINDINGS:
  n=23 of the 40 labs that used off-site testing only used one type of off-site lab.
  Usually either Hospital Network central lab (n=10) or Commercial lab (n=10)
  (the other two labs that only used one type of off-site lab used PH lab)
 
  n=10 used two types of off-site labs. All but one used commercial lab.
  Most also used PH lab (n=6) and others also used Hospital Network central lab (n=3).
 *____________________________________________________________________________________________*/


   PROC FREQ data= L_complete ;
      where  anycovidtestingoffsite =1 ;
      tables  OffsiteHospLab  OffsitePHlab  OffsiteCommLab  offsiteotherlab  ;
run;
/*____________________________________________________________________________________________*
 FINDINGS:
 | About two thirds of the 40 labs (n=27) that used off-site testing used a commercial lab.
 | Almost half (n=19) used off-site Hospital Network central lab and n=16 used PH lab.
 *____________________________________________________________________________________________*/



*** Off-site Testing - Reasons for using off-site Lab ***;
***---------------------------------------------------***;

   proc format;
      value OffRsnFmt 1='Routine Practice' 2='Capacity limitations' 3='Instrument errors' 4='Supply chain issues' ;

** Commercial labs **;
   PROC FREQ data= L_complete ;
      where  OffsiteCommLab =1 ;
      tables   OffsiteCommLab  OffsiteCommLab_Yes  ;
      format OffsiteCommLab_Yes OffRsnFmt. ;
run;
/*____________________________________________________________________________________________*
 FINDINGS:
  The primary reason for using an off-site commercial lab was roughly equal between:
  Routine practice (n=8),  Capacity limitations (n=8),  and Supply chain issues (n=10)
 *____________________________________________________________________________________________*/


** Hospital Network central lab **;
   PROC FREQ data= L_complete ;
      where  OffsiteHospLab =1 ;
      tables   OffsiteHospLab  OffsiteHospLab_Yes  ;
      format OffsiteHospLab_Yes OffRsnFmt. ;
run;
/*____________________________________________________________________________________________*
 FINDINGS:
  The primary reason for using a Hospital Network central lab for off-site testing was 
     Capacity limitations (n=14) though some also cited 
     Supply chain issues (n=5)
 *____________________________________________________________________________________________*/


** Public Health lab **;
   PROC FREQ data= L_complete ;
      where  OffsitePHlab =1 ;
      tables   OffsitePHlab  OffsitePHlab_Yes  ;
      format OffsitePHlab_Yes OffRsnFmt. ;
run;
/*____________________________________________________________________________________________*
 FINDINGS:
  The primary reason for using a Public Health lab for off-site testing was either
     Supply chain issues (n=6) or Routine practice (n=5)
     A few labs indicated they primarily used PH lab for off-site testing for surge (n=3)
 *____________________________________________________________________________________________*/


*** On-site Testing - Types of platforms used ***;
***-------------------------------------------***;

   PROC FREQ data= L_complete;
      tables  AnyCovidTestingOnsite  ;
run;

   proc format;
      value NumAccFmt 1-9999='1-<10k'  10000-24999='10k-25k'  25000-high='25k or more';

   PROC FREQ data= L_complete;
      where AnyCovidTestingOnsite =1 ;
      tables    DateCOVIDtestingOnsite  Num_Specimens  ;
      format DateCOVIDtestingOnsite  month.   Num_Specimens NumAccFmt. ;
run;


   PROC FREQ data= L_complete;
      where AnyCovidTestingOnsite =1 ;
      tables  TestType_PCR  TestType_OMA  TestType_Antigen  TestType_Serology  TestType_WGS  TestType_Other  / missing missprint;
run;


   PROC FREQ data= L_complete;
      where AnyCovidTestingOnsite =1 ;
/*      tables  NumPlatforms  / missing missprint;*/
      tables  NumPlatforms * TestType_PCR * TestType_OMA * TestType_Antigen * TestType_Serology * TestType_WGS    /list missing missprint;

run;

