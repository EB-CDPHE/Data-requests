/**********************************************************************************************
PROGRAM:  Check.Specimens_w_PCR
AUTHOR:   Eric Bush
CREATED:  August 31, 2021
MODIFIED: 
PURPOSE:	 After a SQL data table has been read using Access.Specimens_read, 
            this program can be used to explore the SAS dataset.
INPUT:	 Specimens_w_PCR
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

%Let SpecDSN = Specimens_w_PCR ;

options pageno=1;
   PROC contents data=Specimens_w_PCR  varnum ;  title1 'Specimens_w_PCR';  run;

/*-----------------------------------------------------------------*
 | Check Specimens_w_PCR data for:
 *-----------------------------------------------------------------*/

** Any missing CollectionDate? **;
   PROC means data= Specimens_w_PCR  n nmiss;
      var CollectionDate  LabSpecimenID ;
run;


** How many Specimens per EventID?  **;
   PROC freq data = Specimens_w_PCR  NOPRINT ;
      where CollectionDate ne .;
      tables  EventID*CollectionDate / out=Event_Coll_Count ;
run;

/*      proc print data= Event_Coll_Count; where count=1;     run;*/
/*      proc print data= Specimens_w_PCR; where EventID='1000140'; */
/*         var EventID  LabSpecimenID CollectionDate   ;*/
/*run;*/

   PROC freq data = Event_Coll_Count;
      tables COUNT;
      title1 'Specimens_w_PCR';
      title2 'Frequency of Collection Dates per EventID';
run;


proc print data= Event_Count;
where count>50;
run;

   proc sort data= Specimens_w_PCR
               out= Specimens_w_PCR_Sort ;
      by EventID  CollectionDate   LabSpecimenID  ;
run;

   PROC print data= Specimens_w_PCR_Sort ;
      where EventID in 
         ('1007196', '1210721', '552404', '647800', '664619', '741091', '792031', '998246'
         );
      ID EventID; 
      by EventID;
      var LabSpecimenID  Specimen  CollectionDate   ResultDate_TT229  ResultText_TT229  ;
      format Specimen  $10.;
run;



/*-----------------------------------------------------------------*
 | Check CEDRS_fix data for:
 *-----------------------------------------------------------------*/


** Any missing CollectionDate? **;
   PROC means data= COVID.CEDRS_view_fix   n nmiss;
      var   ReportedDate   CollectionDate    ;
run;



    proc sort data= COVID.CEDRS_view_fix
               out= CEDRS_sort ;
      by EventID  CollectionDate     ;
run;



** How many Specimens per EventID?  **;
   PROC freq data = CEDRS_sort  NOPRINT ;
      where CollectionDate ne .;
      tables  EventID*CollectionDate / out=CEDRS_Coll_Count ;
run;

   PROC freq data = CEDRS_Coll_Count;
      tables COUNT;
      title1 'COVID.CEDRS_view_fix';
      title2 'Frequency of Collection Dates per EventID';
run;







   PROC print data= CEDRS_sort ;
      where EventID in 
         ('1007196', '1210721', '552404', '647800', '664619', '741091', '792031', '998246'
         );
      ID EventID; 
      by EventID;
      var   CollectionDate   ReportedDate  Earliest_CollectionDate ;
      format Specimen  $10.;
      title1 'CEDRS_sort';
run;




/*-----------------------------------------------------------------*
 | Check SwP2 data for:
 *-----------------------------------------------------------------*/
** Any missing CollectionDate? **;
   PROC means data= SwP2   n nmiss;
      var   LabSpecimenID   CollectionDate    ;
run;

** How many Specimens per EventID?  **;
   PROC freq data = SwP2  NOPRINT ;
      where CollectionDate ne .;
      tables  EventID*CollectionDate / out=SwP2_Coll_Count ;
   PROC freq data = SwP2_Coll_Count;
      tables COUNT;
      title1 'SwP2';
      title2 'Frequency of Collection Dates per EventID';
run;





/*-----------------------------------------------------------------*
 | Check CEDRS_PCR1 data for:
 *-----------------------------------------------------------------*/

   PROC print data= CEDRS_PCR1 ;
      ID EventID; 
      by EventID;
      var LabSpecimenID   CollectionDate   ReportedDate  Earliest_CollectionDate   Specimen  CollectionDate   ResultDate_TT229  ResultText_TT229  ;
      format Specimen  $10.;
      title1 'CEDRS_sort';
run;



/*-----------------------------------------------------------------*
 | Check CEDRS_PCR2 data for:
 *-----------------------------------------------------------------*/

** Any missing CollectionDate? **;
   PROC means data= CEDRS_PCR2   n nmiss;
      var   ReportedDate   CollectionDate  LabSpecimenID  ;
run;


** How many Collection Dates per EventID?  **;
   PROC freq data = CEDRS_PCR2  NOPRINT ;
      where CollectionDate ne .;
      tables  EventID*CollectionDate / out=PCR2_Coll_Count ;
run;

   PROC freq data = PCR2_Coll_Count;
      tables COUNT;
      title1 'CEDRS_PCR2';
      title2 'Frequency of Collection Dates per EventID';
run;


** Which PCR tests were added?  **;
/*DATA extrarec;  set CEDRS_PCR2;*/
/*   by EventID CollectionDate;*/
/**/
/*   if first.EventID ne last.EventID;*/
/*run;*/
/*   PROC print data= extrarec;*/
/*      where collectiondate='31JUL21'd;*/
/*      id EventID;*/
/*      by EventID;*/
/*      var LabSpecimenID   CollectionDate   ReportedDate  Earliest_CollectionDate   Specimen  CollectionDate   ResultDate_TT229  ResultText_TT229  ;*/
/*      format Specimen  $10.;*/
/*      title1 'CEDRS_PCR2 extra records';*/
/*      title2 'Extra records added to CEDRS_PCR1 when creating CEDRS_PCR2';*/
/*run;*/


proc sort data=
            out= ;
   by EventID CollectionDate ReportedDate ;



/*-----------------------------------------------------------------*
 | Check SwP2 data for:
 *-----------------------------------------------------------------*/
** Any missing CollectionDate? **;

   PROC means data= SwP3   n nmiss;
      var   LabSpecimenID   CollectionDate    ;
run;

** How many Specimens per EventID?  **;
   PROC freq data = SwP3  NOPRINT ;
/*      where CollectionDate ne .;*/
      tables  EventID*CollectionDate / out=SwP3_Coll_Count ;
   PROC freq data = SwP3_Coll_Count;
      tables COUNT  / missing missprint;
      title1 'SwP3';
      title2 'Frequency of Collection Dates per EventID';
run;



/*-----------------------------------------------------------------*
 | Check COVID_Sequence data for:
 *-----------------------------------------------------------------*/
title1 'COVID_Sequence';
** Any missing CollectionDate? **;
   PROC means data= COVID_Sequence   n nmiss;
      var  LabSpecimenID  ResultDate_TT436  ResultDate  ;
run;


** How many Specimens per EventID?  **;
   PROC freq data = COVID_Sequence  NOPRINT ;
      tables  EventID*LabSpecimenID / out=COVID_Sequence_Count ;
   PROC freq data = COVID_Sequence_Count;
      tables COUNT;
      title1 'COVID_Sequence';
      title2 'Frequency of LabSpecimenID per EventID';
run;


/*-----------------------------------------------------------------*
 | Check again CEDRS_PCR2 data for:
 *-----------------------------------------------------------------*/
title1 'CEDRS_PCR2';

** Any missing CollectionDate? **;
   PROC means data= CEDRS_PCR2   n nmiss;
      var LabSpecimenID  ReportedDate   CollectionDate   ResultDate_TT229 ;
run;

** How many Specimens per EventID?  **;
   PROC freq data = CEDRS_PCR2  NOPRINT ;
      tables  EventID*LabSpecimenID / out=CEDRS_PCR2_Count2 ;
   PROC freq data = CEDRS_PCR2_Count2;
      tables COUNT;
      title1 'CEDRS_PCR2';
      title2 'Frequency of LabSpecimenID per EventID';
run;





/*-----------------------------------------------------------------*
 | Check NOMATCH2 data for:
 *-----------------------------------------------------------------*/

** Any missing CollectionDate? **;
   PROC means data= NOMATCH2   n nmiss;
      var      CollectionDate   LabSpecimenID ;
run;

** How many Specimens per EventID?  **;
   PROC freq data = NOMATCH2  NOPRINT ;
      where CollectionDate ne .;
      tables  EventID*CollectionDate / out=NOMATCH2_Count ;
run;

   PROC freq data = NOMATCH2_Count;
      tables COUNT;
      title1 'NOMATCH2';
      title2 'Frequency of Collection Dates per EventID';
run;







***  3. Evaluate "SpecimenTypeID" and "Specimen" variables  ***;
***---------------------------------------------------------***;

   PROC freq data = &SpecDSN  order=freq;
      tables SpecimenTypeID * Specimen /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | SpecimenTypeID is a two digit numeric code assigned to Specimen types. 
 | Specimen describes the Specimen type.
 *_______________________________________________________________________________*/


***  4. Examine records with duplicate LabSpecimenID's  ***;
***-----------------------------------------------------***;

   PROC freq data = &SpecDSN  NoPrint ;
      tables  LabSpecimenID / out=Specimen_Count ;
   PROC freq data = Specimen_Count;
      tables COUNT;
run;

/*_______________________________________________________________________*
 |FINDINGS:
 | LabSpecimenID is a numeric ID that can be 1 to 7 digits long. 
 | There are NO duplicate LabSpecimenID 's in this dataset.
 *_______________________________________________________________________*/


***  5. Evaluate date variables  ***;
***------------------------------***;

** Missing values for date variables **;
   PROC means data = &SpecDSN  n nmiss ;
      var CollectionDate  CreatedDate  UpdatedDate ; 
run;

/*_______________________________________________________*
 |FINDINGS:
 | CreatedDate has no missing values. 
 | UpdatedDate exists for approx 1.5% of Specimens.
 | Collection date is missing in < 1% of Specimens.  
 *_______________________________________________________*/


** Invalid values (i.e. date ranges) for date variables **;
   PROC freq data = &SpecDSN  ;
      tables CollectionDate  CreatedDate  UpdatedDate ;
      format CollectionDate  CreatedDate  UpdatedDate  WeekW11. ;
run;

/*____________________________________________________________________________*
 |FINDINGS:
 | All date values are from much earlier time period than COVID. 
 | CollectionDate goes from 1900 to 2106, i.e. there are some wrong values.
 | CreatedDate goes from 1999 to present.
 | UpdatedDate goes from 2017 to present.
 |FIX:
 | Re-do data check after merging with COVID LabTests.
 *____________________________________________________________________________*/


***  6. Pre-merge analysis  ***;
***------------------------------***;

   proc sort data= Specimens_read
               out= Specimens_sort;
      by LabSpecimenID EventID;
run;

DATA Spec_PCR; 
   merge Lab_TT229_fix(in=pcr)  Specimens_read(in=s) ;
   by LabSpecimenID EventID;
   
   if pcr=1 then TT229_in=1; else TT229_in=0;
   if s=1 then Spec_in=1; else Spec_in=0;
run;

   PROC freq data= Spec_PCR ;
      tables Spec_in * TT229_in ;
run;

** Print record that has PCR test but is NOT in Specimen dataset **;
   proc print data= Spec_PCR;  where Spec_in=0 and TT229_in=1; run;
   proc print data= Specimens_read;  where EventID='722098'; run;

/*______________________________________________________________________________________________*
 |FINDINGS:
 | n=2,298,171 records in Specimens
 | n=1,372,307 records with PCR test - all but 1 are in Specimens dataset
 | EventID= 722098 and LabSpecimenID= 840399 is missing from Specimens though has PCR test
 *______________________________________________________________________________________________*/

