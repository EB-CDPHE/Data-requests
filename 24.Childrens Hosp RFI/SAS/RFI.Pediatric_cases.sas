/**********************************************************************************************
PROGRAM:  RFI.Pediatric_cases.sas
AUTHOR:   Eric Bush
CREATED:  January 22, 2022
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=50 ls=150 ;     * Landscape pagesize settings *;
options ps=65 ls=110 ;     * Portrait pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;

   PROC contents data=COVID.CEDRS_view_fix  varnum ;  title1 'COVID.CEDRS_view_fix';  run;


*** Create local copy of filtered data for selected variables  ***;
***------------------------------------------------------------***;

DATA CEDRS_minors;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND  
      Age_at_Reported < 18  AND  
      ('01MAR20'd le ReportedDate le '31AUG21'd) ;

        if ('01MAR20'd le ReportedDate le '30SEP20'd) then TP=1 ;
   else if ('01OCT20'd le ReportedDate le '31MAR21'd) then TP=2 ;
   else if ('01APR21'd le ReportedDate le '31AUG21'd) then TP=3 ;

   Keep  ProfileID  EventID  Casestatus  CountyAssigned   ReportedDate   Age_at_Reported   CollectionDate   
         Outbreak_Associated   Symptomatic  OnsetDate hospitalized  hospitalized_cophs
         Single_Race_Ethnicity  Race  Ethnicity  TP  ;
run;

   PROC contents data=CEDRS_minors  varnum ;  title1 'CEDRS_minors';  run;

   PROC freq data=CEDRS_minors ;
      tables CaseStatus  TP ;
run;


   PROC format;
      value $ RaceFmt
         'Multiple','Other' = 'Multiple/Other' ;
run;
   PROC freq data= CEDRS_minors   ;
      where CaseStatus = 'confirmed';
/*      table Ethnicity * Race   / list missing missprint ;*/
      table Ethnicity   /  missing missprint ;
      format Race $RaceFmt. ;
title3 "Ethnicity for CaseStatus = 'confirmed'";
run; 

   PROC freq data= CEDRS_minors  order=freq ;
      where CaseStatus = 'confirmed'  AND  Ethnicity = 'Not Hispanic or Latino' ;
      table Race   /  missing missprint ;
      format Race $RaceFmt. ;
title3 "Race by Non-Hispanics for CaseStatus = 'confirmed'";
run; 


**  Define Age groups  **;
   PROC format;
      value AgeFmt
         0-<5='Infant'
         5-<12='Kid'
         12-<18='Teen'
         18-115='Adult' ;
run;

   PROC freq data= CEDRS_minors  ;
      where CaseStatus = 'confirmed' ;
      tables Age_at_Reported * TP / chisq;
      format Age_at_Reported AgeFmt.;
title3 "Age group for CaseStatus = 'confirmed'";
run;





** All together **;

   PROC freq data= CEDRS_minors   ;
      where CaseStatus = 'confirmed';
      table Ethnicity * TP  /  missing missprint ;
      format Race $RaceFmt. ;
title3 "Ethnicity for CaseStatus = 'confirmed' by Time Period";
run; 

   PROC freq data= CEDRS_minors   ;
      where CaseStatus = 'confirmed'  AND  Ethnicity = 'Not Hispanic or Latino' ;
      table Race  * TP  /  missing missprint ;
      format Race $RaceFmt. ;
title3 "Race by Non-Hispanics for CaseStatus = 'confirmed' by Time Period";
run; 
