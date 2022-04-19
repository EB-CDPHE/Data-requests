/**********************************************************************************************
PROGRAM:   Access.Events
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.Events
OUTPUT:		       Events_read
***********************************************************************************************/

/*--------------------------------------------------------------------*
 | What this program does:
 | 1. Define library to access COVID19 database on dbo144 server using ODBC
 | 2. Create temp SAS dataset from SQL table and report findings
 | 3. Modify SAS dataset per Findings
 |    a) Convert temporary numeric ID variable character ID var using the CATS function
 | 4. Shrink character variables in data set to shortest possible length (based on longest value)
 | 5. Define library to store permanent SAS dataset
 | 6. Rename "shrunken" SAS dataset
 | 7. PROC contents of final dataset
 *--------------------------------------------------------------------*/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;

LIBNAME CEDRS66   ODBC  dsn='CEDRS_III_Warehouse' schema=cedrs;  run;

/*_______________________________________________________*
 |NOTE:  
 | ** DiseaseID=159 for Disease='COVID-19'
 | ** EventStatusID=??? for EventStatus='Confirmed'
 | ** EventStatusID=??? for EventStatus='Probable'
 *_______________________________________________________*/


**  2. Create temp SAS dataset from SQL table  **;
DATA Events; set CEDRS66.Events; 
   if DiseaseID =159  AND   Deleted=0 ;
run; 

** Review contents of SAS dataset **;
PROC contents data=Events  varnum ;  run;   
/*_______________________________________________________________________*
 |NOTE:
 | EventStatusID=263 for EventStatus='Confirmed'
 | EventStatusID=264 for EventStatus='Does not meet case definition'
 | EventStatusID=265 for EventStatus='Probable'
 | EventStatusID=266 for EventStatus='Suspect'
 | EventStatusID=267 for EventStatus='Unknown'
 |
 | OutcomeID=277 for Outcome='Alive'
 | OutcomeID=278 for Outcome='Patient Died' 
 | OutcomeID=278 for Outcome='Unknown' 
 *_______________________________________________________________________*/

proc freq data= Events;  tables DiseaseID  OutcomeID EventStatusID  Deleted ;  run;


** 3. Modify SAS dataset per Findings **;
DATA Events_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Events(rename=
                   (ProfileID=tmp_ProfileID 

                    ReportedDate=tmp_ReportedDate
                    CountedDate=tmp_CountedDate
                    DiagnosisDate=tmp_DiagnosisDate
                    OnsetDate=tmp_OnsetDate
                    InvestigationStartDate=tmp_InvestStartDate
                    InfectiousPeriodStart=tmp_InfectiousPeriodStart
                    InfectiousPeriodEnd=tmp_InfectiousPeriodEnd
                    CDCReportDate=tmp_CDCReportDate
                    ExpectedDeliveryDate=tmp_ExpectedDeliveryDate
                    ActualDeliveryDate=tmp_ActualDeliveryDate
                    AssignedDate=tmp_AssignedDate
                    AssignedDate2=tmp_AssignedDate2
                    InvestigationCompletedDate=tmp_InvestCompletedDate
                    ClosedDate=tmp_ClosedDate
                    DateCounted=tmp_DateCounted
                    SurveySentDate=tmp_SurveySentDate
                    CoreDataOKDate=tmp_CoreDataOKDate
                    CreatedDate=tmp_CreatedDate
                    UpdatedDate=tmp_UpdatedDate  )
                  ); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ProfileID = cats(tmp_ProfileID);

* Extract date part of a datetime variable  *;
   ReportedDate = datepart(tmp_ReportedDate);   format ReportedDate yymmdd10.;
   CountedDate = datepart(tmp_CountedDate);   format CountedDate yymmdd10.;
   DiagnosisDate = datepart(tmp_DiagnosisDate);   format DiagnosisDate yymmdd10.;
   OnsetDate = datepart(tmp_OnsetDate);   format OnsetDate yymmdd10.;
   InvestigationStartDate = datepart(tmp_InvestStartDate);   format InvestigationStartDate yymmdd10.;
   InfectiousPeriodStart = datepart(tmp_InfectiousPeriodStart);   format InfectiousPeriodStart yymmdd10.;
   InfectiousPeriodEnd = datepart(tmp_InfectiousPeriodEnd);   format InfectiousPeriodEnd yymmdd10.;
   CDCReportDate = datepart(tmp_CDCReportDate);   format CDCReportDate yymmdd10.;
   ExpectedDeliveryDate = datepart(tmp_ExpectedDeliveryDate);   format ExpectedDeliveryDate yymmdd10.;
   ActualDeliveryDate = datepart(tmp_ActualDeliveryDate);   format ActualDeliveryDate yymmdd10.;
   AssignedDate = datepart(tmp_AssignedDate);   format AssignedDate yymmdd10.;
   AssignedDate2 = datepart(tmp_AssignedDate2);   format AssignedDate2 yymmdd10.;
   InvestigationCompletedDate = datepart(tmp_InvestCompletedDate);   format InvestigationCompletedDate yymmdd10.;
   ClosedDate = datepart(tmp_ClosedDate);   format ClosedDate yymmdd10.;
   DateCounted = datepart(tmp_DateCounted);   format DateCounted yymmdd10.;
   SurveySentDate = datepart(tmp_SurveySentDate);   format SurveySentDate yymmdd10.;
   CoreDataOKDate = datepart(tmp_CoreDataOKDate);   format CoreDataOKDate yymmdd10.;
   CreatedDate = datepart(tmp_CreatedDate);   format CreatedDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;

   DROP tmp_:  ;

run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Events_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Events_read ;  
/*   length ProfileID $ 9;  */
   set Events_temp_ ;

/*   format ProfileID $9.;*/
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=Events_read ; title1 'Events_read'; run;


*** Explore data ***;
***--------------***;

   proc freq data=Events_read;
      tables DiseaseID ;
run;

   proc freq data=Events_read;
/*      tables HospitalizedID ;*/
/*      tables HomelessID ;*/
/*      tables LiveInInstitution ;*/
/*      tables ExposureFacilityID ;*/
/*      tables InvestigationStatusID ;*/
/*      tables OnsetDateUnavailable ;*/
/*      tables PregnantID ;*/
/*      tables OutbreakID ;*/
      tables PregnantID ;

run;


