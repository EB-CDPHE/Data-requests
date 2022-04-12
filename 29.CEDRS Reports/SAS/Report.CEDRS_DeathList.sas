/**********************************************************************************************
PROGRAM:   Report.CEDRS_DeathList
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  	
PURPOSE:   Explore response categories for variables in the LPHA report: COVID-19 Deaths Listing 
INPUT:	  
OUTPUT:		        
***********************************************************************************************/

/*-----------*
 |NOTES:
 *-----------*/

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


      PROC freq data= DeathList;
         tables GenderID ;
run;

   proc print data=Codes_read;
      where CodeID in (7, 8, 9,10,11);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

   proc print data=Codes_read;
      where ConceptGroup = 'State_FIPS';
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

   proc print data=Codes_read;
      where CodeID in (119,120,121);
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format ConceptName  PreferredConceptName  ConceptGroup  $25. ;
run;

   proc print data=Codes_read;
      where ConceptGroup = 'InstitutionType';
      id CodeID; var ConceptName  PreferredConceptName  ConceptGroup  Value;
      format  ConceptGroup  $15.  ConceptName  PreferredConceptName $40. ;
run;
