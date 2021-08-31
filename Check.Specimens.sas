/**********************************************************************************************
PROGRAM:  Check.Specimens
AUTHOR:   Eric Bush
CREATED:  August 30, 2021
MODIFIED: 
PURPOSE:	 After a SQL data table has been read using Access.Specimens_read, 
            this program can be used to explore the SAS dataset.
INPUT:	 Specimens_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/

%Let SpecDSN = Specimens_read ;

options pageno=1;
   PROC contents data=Specimens_read  varnum ;  title1 'Specimens_read';  run;

/*-----------------------------------------------------------------*
 | Check Lab_TT437_read data for:
 |  1. Evaluate "CreatedID" and "Created" variables
 |  2. Evaluate "UpdatedID" and "Updated" variables
 |  3. Evaluate "SpecimenTypeID" and "Specimen" variables
 |  4. Examine records with duplicate LabSpecimenID's
 |  5. Evaluate date variables
 *-----------------------------------------------------------------*/


***  1. Evaluate "CreatedID" and "Created" variables  ***;
***---------------------------------------------------***;

   PROC freq data = &SpecDSN  order=freq;
      tables CreatedID * Created /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | CreatedID is the numeric code assigned to names
 | Created holds the names.
 | Over 60% of Specimens were created by "System Admin" (38%) or ELRAutoImport (23%).
 *_______________________________________________________________________________*/


***  2. Evaluate "UpdatedID" and "Updated" variables  ***;
***---------------------------------------------------***;

Data &SpecDSN._temp; set &SpecDSN;
UpdatedAbbrev = scan(Updated,1,' '); 

   PROC freq data = &SpecDSN._temp order=freq;
      tables UpdatedID * UpdatedAbbrev /list; ** Name of person that created the test result record;
run;

/*_______________________________________________________________________________*
 |FINDINGS:
 | UpdatedID is the numeric code assigned to names. There are multiple names assigned to each code.
 | However, all names assigned to a code have the same first name but different last name.
 | Updated holds the names.
 | 
 *_______________________________________________________________________________*/


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

