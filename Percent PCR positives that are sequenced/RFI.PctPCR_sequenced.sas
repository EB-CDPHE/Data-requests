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

   if CollectionDate = . then CollectionDate = ReportedDate;

   KEEP
      ProfileID  EventID  LabSpecimenID                           /* key variables */
      CollectionDate  ReportedDate                               /* filter variables */
      CaseStatus  County                                          /* grouping variables */
      Specimen SpecimenTypeID                                     /* Specimen-level variables */
      TestTypeID_TT229  TestType_TT229   ResultDate_TT229         /* PCR variables */
      ResultID_TT229  ResultText_TT229  QuantitativeResult_TT229  
      ReferenceRange_TT229  CreateDate_TT229
      TestTypeID_TT437  TestType_TT437   ResultDate_TT437         /* Variant data */
      ResultID_TT437  ResultText_TT437  QuantitativeResult_TT437  
      ReferenceRange_TT437  CreateDate_TT437   Variant_Type 
      TestTypeID_TT436  TestType_TT436   ResultDate_TT436         /* VOC data */
      ResultID_TT436  ResultText_TT436  QuantitativeResult_TT436  
      ReferenceRange_TT436
      Earliest_CollectionDate                                     /* Misc vars */
;

run;
 

*** CollectionDate ***;
***----------------***;

title;
   PROC means data=WGS n nmiss ;
      var ReportedDate  CollectionDate  Earliest_CollectionDate    ;
run;

   PROC freq data=WGS;
      tables CollectionDate / out=Spec_by_week;
      format CollectionDate WeekW5. ;
run;

** FILTER:  CollectionDate > 12/31/20 **;
   PROC means data=WGS n nmiss ;
      where ReportedDate > '31DEC20'd;
      var ReportedDate  CollectionDate  Earliest_CollectionDate    ;
run;



DATA WGS_CY21;  set WGS;  
   where ReportedDate > '31DEC20'd;
run;


*** Specimens with PCR testing ***;
***----------------------------***;

   PROC means data=WGS_CY21 n nmiss ;
      var ReportedDate  CollectionDate  LabSpecimenID TestTypeID_TT229  ResultID_TT229   ResultDate_TT229   ;
run;

   proc format;
      value Result_TT229_fmt
         1 = 'Positive'
         2 = 'Negative'
         4 = 'Indeterminate'
         9 = 'Unknown' ;

   PROC freq data=WGS_CY21;
/*      tables ResultID_TT229 * ResultText_TT229 / list ;*/
      tables ResultID_TT229 ;
      format ResultID_TT229 Result_TT229_fmt. ;
run;


*** Sequencing - Variant type  ***;
***----------------------------***;

   PROC means data=WGS_CY21 n nmiss ;
      var ReportedDate  CollectionDate  LabSpecimenID TestTypeID_TT437  ResultID_TT437   ResultDate_TT437  CreateDate_TT437 ;
run;
proc freq data=WGS_CY21; 
      where CreateDate_TT437 > '24AUG21'd;
table  CreateDate_TT437; run;


   PROC means data=WGS_CY21 n nmiss ;
      where CollectionDate > '24AUG21'd;
      var ReportedDate  CollectionDate  LabSpecimenID ResultDate_TT437   ;
      class CreateDate_TT437;
run;
   PROC freq data=WGS_CY21;
      where CollectionDate > '24AUG21'd;
      tables CreateDate_TT437 ;
run;


   PROC freq data=WGS_CY21;
      tables TestType_TT437  ResultID_TT437 * Variant_Type / list ;
run;

   PROC freq data=WGS_CY21  order=freq;
      tables Variant_Type  ;
run;


** Proportion of PCR that is sequenced **;
   PROC freq data=WGS_CY21;
      where ResultID_TT229 = 1;
      tables  ResultID_TT229 * TestType_TT437  / list missing missprint;
      tables  ResultID_TT229 * TestType_TT437  / list missing missprint;
     format ResultID_TT229 Result_TT229_fmt. ;
run;


** Sequenced by week **;
   PROC freq data=WGS_CY21;
      tables ResultDate_TT437 / out=WGS_by_week;
      format ResultDate_TT437 WeekW5. ;
run;


*** Percent Positive PCR's that are sequenced each week ***;

/*
 |NOTE:
 | Sum ResultID_TT229 = 1 for each week to get weekly number of PCR positive specimens
 | Sum ResultID_TT437 in (1061-1089) by week to get number of sequences
 | Week based on CreateDate for the RT_PCR lab test
 */


   PROC means data=WGS_CY21 n nmiss ;
      var ReportedDate  CollectionDate  LabSpecimenID  CreateDate_TT229  CreateDate_TT437 ;
run;


   proc format;
      value Variant_Fmt
       1061-1064 = 'Sequence successful'
       1073-1089 = 'Sequence successful' ;
      value Cat2_fmt 1='Positive' 2,4,9='NOT Positive' ;
run;

* Denom = PCR positives *;
   proc freq data=WGS_CY21  noprint;
     where ResultID_TT229 =1 ;
     table CreateDate_TT229  / out=WGS_Denom ;
     format CreateDate_TT229 WeekW5. ;
run;

* Numer = variant type reported *;
   proc freq data=WGS_CY21  noprint;
     where ResultID_TT229 =1 ;
     table CreateDate_TT437  / out=WGS_Number  ;
     format CreateDate_TT437 WeekW5. ;
run;



*** END ***;


   PROC freq data= WGS ;
/*      tables CaseStatus ;*/
/*      tables TestTypeID * TestType ;*/
      tables ResultID_TT229 * ResultText_TT229  / list  ;

run;


** PCR summary **;



title; run;




   PROC SQL;
      select count(distinct EventID) as NumPeople
      from CASES_w_PCR 
      where ResultID_TT229 ne .
      group ResultID_TT229;
run;





