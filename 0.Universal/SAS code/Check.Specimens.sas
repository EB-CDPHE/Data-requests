/**********************************************************************************************
PROGRAM:  Check.Specimens
AUTHOR:   Eric Bush
CREATED:  August 30, 2021
MODIFIED: 090121
PURPOSE:	 After a SQL data table has been read using Access.Specimens_read, 
            this program can be used to explore the SAS dataset.
INPUT:	 Specimens_reduced   OR   Specimens_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

%Let SpecDSN = Specimens_reduced ;

options pageno=1;
   PROC contents data=Specimens_reduced  varnum ;  title1 'Specimens_reduced';  run;

/*-----------------------------------------------------------------*
 | Check Specimens_read data for:
 |  1. Evaluate "CreatedID" and "Created" variables
 |  2. Evaluate "UpdatedID" and "Updated" variables
 |  3. Evaluate "SpecimenTypeID" and "Specimen" variables
 |  4. Examine records with duplicate LabSpecimenID's
 |  5. Number of specimens per EventID
 |  6. Evaluate date variables
 *-----------------------------------------------------------------*/


***  1. Evaluate "CreatedID" and "Created" variables  ***;
***---------------------------------------------------***;
   PROC freq data = &SpecDSN  order=freq;
      tables CreatedID * Created /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________________*
 |FINDINGS:
 | CreatedID is the numeric code assigned to names
 | Created holds the names.
 | 80% of Specimens were created by "System Admin" (50%) or ELRAutoImport (30%).
 *_______________________________________________________________________________________*/


***  2. Evaluate "UpdatedID" and "Updated" variables  ***;
***---------------------------------------------------***;
Data &SpecDSN._temp; set &SpecDSN;
UpdatedAbbrev = scan(Updated,1,' '); 

   PROC freq data = &SpecDSN._temp order=freq;
      tables UpdatedID * UpdatedAbbrev /list; ** Name of person that created the test result record;
run;

   PROC means data = &SpecDSN  n nmiss;
      var LabSpecimenID  CollectionDate  UpdatedID;
run;

/*____________________________________________________________________________________________________*
 |FINDINGS:
 | UpdatedID is the numeric code assigned to names. There are multiple names assigned to each code.
 | However, all names assigned to a code have the same first name but different last name.
 | Updated holds the names.
 | UpdatedID had data in only <1% of records
 *____________________________________________________________________________________________________*/


***  3. Evaluate "SpecimenTypeID" and "Specimen" variables  ***;
***---------------------------------------------------------***;
   PROC freq data = &SpecDSN  order=freq;
      tables SpecimenTypeID * Specimen /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | SpecimenTypeID is a two digit numeric code assigned to Specimen types. 
 | Specimen describes the Specimen type.
 | Over 90% of specimens either "NP Swab" (61%) or "Other" (31%).
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


***  5. Number of specimens per EventID  ***;
***--------------------------------------***;
   PROC freq data = &SpecDSN   ;
      tables  EventID  /  out=Specimen_per_EventID ;
   PROC freq data = Specimen_per_EventID;
      tables COUNT;
run;
   PROC means data= Specimen_per_EventID  n min max median mean  maxdec=2;
      var COUNT;
run;
/*_________________________________________________________________________________________________*
 |FINDINGS:
 | The frequency distribution of EventID gives the count of LabSpecimenID per EventID 
 | (since only one LSI per record)
 | More than 75% of EventID's had 1 (54%) or 2 (24%) specimens.
 | The number of specimens per EventID ranged from 1-215 with a median of 1 (and mean = 2.6).
 *_________________________________________________________________________________________________*/


***  6. Evaluate date variables  ***;
***------------------------------***;

** Missing values for date variables **;
   PROC means data = &SpecDSN  n nmiss ;
      var  CreatedDate  CollectionDate  UpdatedDate ; 
run;

/*_______________________________________________________*
 |FINDINGS:
 | CreatedDate has no missing values. 
 | Collection date is missing in < 0.3% of Specimens.  
 | UpdatedDate exists for approx 0.7% of Specimens.
 *_______________________________________________________*/


** Invalid values (i.e. date ranges) for date variables **;
   PROC freq data = &SpecDSN  ;
      tables CreatedDate  CollectionDate  UpdatedDate ;
/*      format CreatedDate  CollectionDate  UpdatedDate  WeekW11. ;*/
run;

/*____________________________________________________________________________*
 |FINDINGS:
 | CreatedDate goes from 3/5/20 to present.
 | CollectionDate used to go from 1901 to 12/5/21, i.e. there are some wrong values.
 | CollectionDate now goes from 1/2/2020 to present.
 | UpdatedDate goes from 3/5/20 to present.
 |FIX:
 | Previous data errors fixed at source via LeAnna Kent.
 *____________________________________________________________________________*/

/*   PROC print data= &SpecDSN ;*/
/*      where (. < CollectionDate < '01JAN20'd)  OR  CollectionDate > '01NOV21'd;*/
/*      id LabSpecimenID ;*/
/*      var EventiD CreatedDate  CollectionDate  UpdatedDate  Specimen   ;*/
/*    title1 'Specimens_reduced';*/
/*    title2 'CollectionDate > Nov 1, 2020';*/
/*run;*/

** NOTE: ALL of the FINDINGS below have been fixed at source **;

/*____________________________________________________________________________*
 |FINDINGS:
 | LSI=1561333 (EventID=1072252) - CollectionDate mistakenly set to DOB
 | LSI=1689658 (EventID=1113099) - CollectionDate mistakenly set to DOB
 | LSI=2431550 (EventID=1302922) - CollectionDate mistakenly set to DOB
 | LSI=1149683 (EventID=913588)  - CollectionDate mistakenly set to DOB
 | LSI=1293814 (EventID=981962)  - CollectionDate mistakenly set to DOB
 |
 |FIX:
 | LSI=1561333 (EventID=1072252) - set CollectionDate = CreatedDate
 | LSI=1689658 (EventID=1113099) - set CollectionDate = CreatedDate
 | LSI=2356909 (EventID=1282253) - set CollectionDate = 8/23/21
 | LSI=2412211 (EventID=1298160) - set CollectionDate = 8/26/21
 | LSI=2420472 (EventID=1299594) - set CollectionDate = 4/23/21 per CEDRS Labs
 | LSI=2430255 (EventID=1302072) - set CollectionDate = 9/2/21 per CEDRS Labs
 | LSI=2431550 (EventID=1302922) - set CollectionDate = 9/2/21 per CEDRS Labs
 | LSI=1149683 (EventID=913588)  - set CollectionDate = .
 | LSI=1293814 (EventID=981962)  - set CollectionDate = .
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

