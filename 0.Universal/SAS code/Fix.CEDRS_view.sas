/**********************************************************************************************
PROGRAM:  Fix.CEDRS_view
AUTHOR:   Eric Bush
CREATED:	 July 6, 2021
MODIFIED: 	
PURPOSE:	 Explore created SAS dataset
INPUT:	       CEDRS_view_read    zDSI_Events_fix
OUTPUT:	 COVID.CEDRS_view_fix
***********************************************************************************************/

/*-----------------------------------------------------------------------------------------------------------*
 | Fixes made in this code:
 |
 | vv SAS dataset = CEDRS_view_read  vv                 <-- READ dataset         
 | 1. Create County variable from County_Assigned that only includes county name (not ", CO" too)
 | 2. Impute missing values of Age_at_Reported with Age_in_Years from dphse66 zDSI_Events_fix. See NOTE.
 | 3. Contents of final dataset
 |
 |
 | vv SAS dataset = COVID.CEDRS_view_fix   vv           <-- FIX dataset
 | 4. Post-edit data checks on COVID.CEDRS_view_fix
 *-----------------------------------------------------------------------------------------------------------*/

** Contents of the input SAS dataset that was created in the Access.* program and validated with the Check.* programn **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


   PROC contents data=CEDRS_view_read varnum; run;
/*   PROC contents data=zDSI_Events_fix varnum; run;*/


/*____________________________________________________________________________________________________________________*
 | NOTE:                                                                                                              |
 | The variable Age on zDSI_Events is coupled to the Age_Type variable.                                               |
 | Values of Age can be years, months, weeks, or days.                                                                |
 | The FIX.zDSI_Events program was written to convert all age types into years and place in a new variable.           |
 | The new variable, "Age_in_Years", is merged with CEDRS_view and used to impute missing values of Age_at_Reported.  |
 *____________________________________________________________________________________________________________________*/


***  Make edits to CEDRS_view_read and create COVID.CEDRS_view_fix  ***;
***-----------------------------------------------------------------***;

DATA COVID.CEDRS_view_fix ;  set CEDRS_view_read ;
** 1) new county variable  **;
   County = upcase(scan(CountyAssigned,1,',')); 

** 2) bad age values **;
   if EventID= 1260717 then Age_at_Reported=63;
   if EventID= 1294530 then Age_at_Reported=46;
   if EventID= 1392304 then Age_at_Reported=42;

** 3) impute missing collectiondates **;
   if CollectionDate = . then CollectionDate = ReportedDate;

** 4) Premature reports of death **;
   if EventID in ('2134051','2137499') then Outcome='Alive';

run;


**  2. Contents of final SAS dataset  **;

   PROC contents data=COVID.CEDRS_view_fix varnum;  title1 'COVID.CEDRS_view_fix'; 
run;


/*   proc freq data= CEDRS_view_read; tables Outcome; run;*/
/*   proc print data= CEDRS_view_read;*/
/*   where EventID in ('2134051','2137499');*/
/*   id EventID; var ProfileID ReportedDate  CaseStatus  Outcome  ;*/
/*run;*/
/*   proc print data= COVID.CEDRS_view_fix;*/
/*   where EventID in ('2134051','2137499');*/
/*   id EventID; var ProfileID ReportedDate  CaseStatus  Outcome  ;*/
/*run;*/


*** 3.  Post-edit checks ***;
***----------------------***;
   PROC means data= COVID.CEDRS_view_fix n nmiss;
      var ReportedDate    Age_at_Reported   Age_Years;
run;
   PROC freq data= COVID.CEDRS_view_fix;  tables Age_at_Reported /missing missprint; run;
/**/
/*proc univariate data= COVID.CEDRS_view_fix; var Age_years; run;*/
/*proc means data= COVID.CEDRS_view_fix  n nmiss min p1 p10 p25 median mean p75 p90 p99 max   maxdec=2; var Age_years; run;*/
/**/
/*proc means data= COVID.CEDRS_view_fix  n nmiss min p10 p25 median mean p75 p90 max   maxdec=2; var Age_years; run;*/
/**/
/**/
/*proc print data = MMWR_cases;*/
/*where Age_years = .;*/
/*id ProfileID;*/
/*var EventID Age_Years Age Age_Group County CollectionDate ReportedDate hospitalized ;*/
/*run;*/
/**/
/**/
/**/
/*proc print data=MMWR_cases ;*/
/*id ProfileID; var EventID Age Age_Group Age_at_reported Age_Years County ;*/
/*run;*/



   PROC freq data = COVID.CEDRS_view_fix  noprint;
      tables  EventID / out=EventID_Count ;
   PROC freq data = EventID_Count;
      tables COUNT;
run;



