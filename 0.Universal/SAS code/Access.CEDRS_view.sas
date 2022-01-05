/**********************************************************************************************
PROGRAM:  Access.CEDRS_view
AUTHOR:   Eric Bush
CREATED:  July 14, 2021
MODIFIED: 101321: Add code to convert VAX fields from char to date var	
PURPOSE:	 A single program to read CEDRS view
INPUT:		dbo144.CEDRS_view
OUTPUT:		       CEDRS_view_read
***********************************************************************************************/

/*------------------------------------------------------------------------------------------------*
 | What this program does:
 | 1. Define library to access COVID19 database on dbo144 server using ODBC
 | 2. Create temp SAS dataset from SQL table and report findings
 | 3. Modify SAS dataset per Findings
 |    a) Convert temporary numeric ID variable character ID var using the CATS function
 |    b) Convert temporary character var for each date field to a date var
 |    c) Extract date part of a datetime variable
 | 4. Shrink character variables in data set to shortest possible length (based on longest value)
 | 5. Define library to store permanent SAS dataset
 | 6. Rename "shrunken" SAS dataset
 | 7. PROC contents of final dataset
 *------------------------------------------------------------------------------------------------*/

** 1. Libname to access COVID19 database on dbo144 server using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;         ** schema contains "CEDRS_view, a copy of CEDRS_dashboard_constrained";


**  2. Review contents of SAS dataset  **;
PROC contents data=dbo144.CEDRS_view  varnum ;  run;    

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |  ID, ProfileID and EventID are numeric instead of character variables.    
 |    --> These need to be converted to character variables prior to running SHRINK macro.     
 |  The following date fields are character variables with date format instead of a numeric variable.
 |    OnsetDate, onsetdate_proxy, onsetdate_proxy_dist, ReportedDate, CollectionDate, DeathDate, 
 |    Earliest_CollectionDate, Data_pulled_as_of
 |    --> ignore onsetdate_proxy; use onsetdate_proxy_dist instead (per Rachel S.)
 |    --> convert these fields to SAS date variables.
 |  Many of the character variables have length of $255.
 |    --> Use the macro "Shrink" to minimize the length of the character variables.
 *________________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA CEDRS_view_temp; 
   set dbo144.CEDRS_view(rename=
                 (ID=tmp_ID   ProfileID=tmp_ProfileID   EventID=tmp_EventID
                  OnsetDate = tmp_OnsetDate  
                  OnsetDate_proxy_dist = tmp_OnsetDate_proxy_dist 
                  ReportedDate = tmp_ReportedDate 
                  CollectionDate = tmp_CollectionDate  
                  DeathDate = tmp_DeathDate
/*                  Earliest_CollectionDate = tmp_Earliest_CollectionDate   */  
                  Data_pulled_as_of = tmp_Data_pulled_as_of
                  Refreshed_on = tmp_refreshed_on  
                  Vax_UTD = tmp_Vax_UTD
                  Vax_FirstDose = tmp_Vax_FirstDose
                  Vax_Booster = tmp_vax_booster
                  COPHS_AdmissionDate = tmp_cophs_admissiondate
                  DateVSDeceased = tmp_datevsdeceased
                  )); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ID = cats(tmp_ID);
   ProfileID = cats(tmp_ProfileID);
   EventID = cats(tmp_EventID);

* Convert temporary character var for each date field to a date var *;
   OnsetDate            = input(tmp_onsetdate, yymmdd10.);            format OnsetDate yymmdd10.;
   OnsetDate_proxy_dist = input(tmp_OnsetDate_proxy_dist, yymmdd10.); format OnsetDate_proxy_dist yymmdd10.;
   ReportedDate         = input(tmp_ReportedDate, yymmdd10.);         format ReportedDate yymmdd10.;
   CollectionDate       = input(tmp_CollectionDate, yymmdd10.);       format CollectionDate yymmdd10.;
   DeathDate            = input(tmp_DeathDate, yymmdd10.);            format DeathDate yymmdd10.;
/*   Earliest_CollectionDate = input(tmp_Earliest_CollectionDate, yymmdd10.); format Earliest_CollectionDate yymmdd10.;*/
   Data_pulled_as_of    = input(tmp_Data_pulled_as_of, yymmdd10.);    format Data_pulled_as_of yymmdd10.;
   Vax_UTD              = input(tmp_Vax_UTD, yymmdd10.);              format Vax_UTD yymmdd10.;
   Vax_FirstDose        = input(tmp_Vax_FirstDose, yymmdd10.);        format Vax_FirstDose yymmdd10.;
   Vax_Booster          = input(tmp_Vax_Booster, yymmdd10.);        format Vax_Booster yymmdd10.;
   COPHS_AdmissionDate  = input(tmp_COPHS_AdmissionDate, yymmdd10.);  format COPHS_AdmissionDate yymmdd10.;
   DateVSDeceased       = input(tmp_DateVSDeceased, yymmdd10.);       format DateVSDeceased yymmdd10.;


* Extract date part of a datetime variable  *;
   Refreshed_on = datepart(tmp_refreshed_on);   format Refreshed_on yymmdd10.;

/*   DROP tmp_:  address:  OnsetDate_proxy ;*/
   DROP tmp_:    OnsetDate_proxy  Earliest_CollectionDate ;  * Earliest_CollectionDate is identical to CollectionDate;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(CEDRS_view_temp)


** 5. Create libname for folder to store permanent SAS dataset  **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA CEDRS_view_read ; set CEDRS_view_temp_ ;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data= CEDRS_view_read  varnum ; title1 'CEDRS_view_read'; run;
