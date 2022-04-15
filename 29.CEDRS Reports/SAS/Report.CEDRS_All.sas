/**********************************************************************************************
PROGRAM:   Report.CEDRS_All
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  	
PURPOSE:   Explore response categories for variables in the LPHA report: COVID-19 Deaths Listing 
INPUT:	  GetProfiles_read   Events_read   Addresses_read    Hospitalizations_read
           ProfileRaces_read   Notes_read   GetDiseases_read  Codes_read 
OUTPUT:		        
***********************************************************************************************/

/*----------------------------------------------------------------*
 | SAS Programs run to access tables used in SQL code:
 | a. Access.GetProfiles
 | b. Access.Events
 | c. Access.Addresses
 | d. Access.Hospitalizations
 | e. Access.ProfileRaces
 | f. Access.Notes
 | g. Access.GetDiseases
 | h. Access.Codes
 *-----------------------------------------------------------------*/

/*-------------------------------------------------------------------*
 |NOTES:
 | Events_read is filtered by DiseaseID=159 (COVID).
 | Profiles from GetProfiles_read are merged with Events_read.
 | The majority of report columns come from these two tables.
 |
 | Common process is to:
 | 1. Freq of [var]ID on source table to get response option codes
 | 2. Print obs from Codes table with where CodeID = [var]ID values
 | 3. Get ConceptGroup from output (from step 2) 
 | 4. Change Proc Print to filter on ConceptGroup
 | --> will give complete list of response options
 *--------------------------------------------------------------------*/


*** Merge Events and Profile tables ***;
***---------------------------------***;

   PROC sort data=GetProfiles_read
               out=GetProfiles_sort ;
      by ProfileID;
run;
   PROC sort data=Events_read
               out=Events_sort ;
      by ProfileID;
run;

Data COVIDreports; merge Events_sort(in=c) GetProfiles_sort ;
   by ProfileID;
   if c=1;
run;

   PROC contents data= COVIDreports ; title1 'COVIDreports'; run;


/*____________________________________________________________________________________*/


   PROC sort data=COVIDreports
               out=COVIDreports_sort ;
      by EventID;
run;
   PROC sort data=LabSpecimens_read
               out=LabSpecimens_sort ;
      by EventID;
run;
   PROC sort data=Labs_read
               out=Labs_sort ;
      by EventID;
run;

Data COVIDreports_labs; merge COVIDreports_sort(in=r) LabSpecimens_sort  Labs_sort ;
   by EventID;
   if r=1;
run;

   PROC contents data= COVIDreports_labs ; title1 'COVIDreports_labs'; run;


/*____________________________________________________________________________________*/



*** Explore variables used in Deaths Listing report ***;
***_________________________________________________***;

** Gender **;
      PROC freq data= DeathList;
         tables GenderID ;
run;

   proc print data=Codes_read;
      where CodeID in (7, 8, 9,10,11);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;


** State **;
   proc print data=Codes_read;
      where ConceptGroup = 'State_FIPS';
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

** Yes/No response options **;
/* NOTE: Use in several columns */
   proc print data=Codes_read;
      where CodeID in (119,120,121);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;


** InstitutionType **;
   proc print data=Codes_read;
      where ConceptGroup = 'InstitutionType';
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format  ConceptGroup  $15.  ConceptName  PreferredConceptName $40. ;
run;


** Investigation Status **;
   proc print data=Codes_read;
      where CodeID in (268,274,2481);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;
   proc print data=Codes_read;
      where ConceptGroup = 'InvestigationStatus';
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format  ConceptGroup  $20.  ConceptName  PreferredConceptName $30. ;
run;


** Race **;

   proc print data=Codes_read;
      where CodeID in (132,133,134,1706);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

   proc print data=Codes_read;
      where ConceptGroup = 'RaceCategory';
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format  ConceptGroup  $15.  ConceptName  PreferredConceptName $45. ;
run;


** Occupation **;

   proc print data=Codes_read;
      where CodeID in (2373,2374,4005,4013);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

   proc print data=Codes_read;
      
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format  ConceptGroup  $15.  ConceptName  PreferredConceptName $45. ;
run;

PROC SQL noprint;
   select ConceptName
   INTO :OccupationList SEPARATED BY '|'
   FROM Codes_read
   where ConceptGroup = 'CDPHEOccupation';

%put &OccupationList;



** Transmission Type **;

      PROC freq data= SurvForm_read;
         tables TransmissionTypeID ;
run;

   proc print data=Codes_read;
      where CodeID in (3999,4000,4001,4002);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;


** County **;

      PROC freq data= SurvForm_read;
         tables ExposureOccurredCountyID ;
run;

   proc print data=Codes_read;
      where CodeID in (191,200,1676,4003);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

   proc print data=Codes_read;
      where ConceptGroup = 'County_FIPS';
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format  ConceptGroup ConceptName   PreferredConceptName $25. ;
run;


** Specimen Type **;

      PROC freq data= COVIDreports_labs;
         tables Specimen * SpecimenTypeID / list ;
run;


   proc freq data=COVIDreports_labs;
      tables LITSSpecimenID ;
run;



   PROC freq data= COVIDreports_labs order=freq;
/*      tables ResultID ;*/
      tables  QuantitativeResult;
run;
