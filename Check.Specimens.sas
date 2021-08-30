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
      format CollectionDate  CreatedDate  UpdatedDate  WeekW5. ;
run;

/*_________________________________________________________________*
 |FINDINGS:
 | All date values are from much earlier time period than COVID. 
 |FIX:
 | Re-do data check after merging with COVID LabTests.
 *_________________________________________________________________*/


