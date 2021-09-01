/**********************************************************************************************
PROGRAM:  RFI.Percent_PCR_sequenced.sas
AUTHOR:   Eric Bush
CREATED:  September 1, 2021
MODIFIED: 	
PURPOSE:	 Code to obtain requested info re: percent of PCR tests that were sequenced 
INPUT:	 
OUTPUT:	 
***********************************************************************************************/


   PROC contents data= COVID.CEDRS_Sequence    ; title1 'COVID.CEDRS_Sequence'; run;


DATA WGS;  set COVID.CEDRS_Sequence;  

  * KEEP
      ProfileID EventID  /* key variables */
      CaseStatus         /* filter variables */
      CaseStatus         /* grouping variables */

;

run;
 

   PROC means data=WGS n nmiss ;
      var LabSpecimenID   CollectionDate  TestTypeID  ResultID  ResultDate   ;
run;


   PROC freq data= WGS ;
/*      tables CaseStatus ;*/
/*      tables TestTypeID * TestType ;*/
      tables ResultID_TT229 * ResultText_TT229  / list  ;

run;




l.TestType='COVID-19 Variant Type' and l.ResultText <> 'Specimen unsatisfactory for evaluation'
yes!
zDSI_LabTests

title; run;




   PROC SQL;
      select count(distinct EventID) as NumPeople
      from CASES_w_PCR 
      where ResultID_TT229 ne .
      group ResultID_TT229;
run;





