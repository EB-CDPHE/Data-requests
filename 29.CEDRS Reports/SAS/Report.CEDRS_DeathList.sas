/**********************************************************************************************
PROGRAM:   Report.CEDRS_DeathList
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

/*----------------------------------------------------------------*
 |NOTES:
 | Events_read is filtered by DiseaseID=159 (COVID).
 | Profiles from GetProfiles_read are merged with Events_read.
 | The majority of report columns come from these two tables.
 *-----------------------------------------------------------------*/


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

Data DeathList; merge Events_sort(in=c) GetProfiles_sort ;
   by ProfileID;
   if c=1;
run;

   PROC contents data= DeathList ; title1 'DeathList'; run;



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
