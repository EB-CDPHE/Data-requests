/**********************************************************************************************
PROGRAM:  Access.Antigen.sas
AUTHOR:   Eric Bush
CREATED:  January 7, 2022
MODIFIED: 	
PURPOSE:	 Access and curate data on COVID Antigen Test Positivity from SQL data table on dhpe144
INPUT:		tests144.Antigen
OUTPUT:		         Antigen
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
LIBNAME tests144  ODBC  dsn='COVID19' schema=tests;  run;


**  2. Review contents of SAS dataset  **;
PROC contents data=tests144.Antigen  varnum ;  run;    

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |  The date_as_of is a character variables that holds date values.
 |    --> convert this field to SAS date variable.
 |  Character variables have length of $255.
 |    --> Use the macro "Shrink" to minimize the length of the character variables.
 *________________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA Antigen_temp; 
   set tests144.Antigen(rename=
                 (PatientID=tmp_PatientID   
                  DateAdded = tmp_DateAdded  
                  Date_of_Birth = tmp_Date_of_Birth  
                  ResultDate = tmp_ResultDate  
                  CollectionDate = tmp_CollectionDate  
                  ReceiveDate = tmp_ReceiveDate
                  ));  

* Convert temporary numeric ID variable character ID var using the CATS function *;
   PatientID = cats(tmp_PatientID);

* Convert temporary character var for each date field to a date var *;
   DateAdded      = input(tmp_DateAdded, yymmdd10.);         format DateAdded yymmdd10.;
   Date_of_Birth  = input(tmp_Date_of_Birth, yymmdd10.);     format Date_of_Birth yymmdd10.;
   ResultDate     = input(tmp_ResultDate, yymmdd10.);        format ResultDate yymmdd10.;
   CollectionDate = input(tmp_CollectionDate, yymmdd10.);    format CollectionDate yymmdd10.;
   ReceiveDate    = input(tmp_ReceiveDate, yymmdd10.);       format ReceiveDate yymmdd10.;

 * Drop unnecessary variables *;
   DROP tmp_:  Medical_Record_Number Replicant  Geo:  Address: Phone
         Sender Submitter Test_Loinc  Reviewed  FileSource  Collection_proxy  Refreshed_ON  Orig_DateAdded ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Antigen_temp)


** 5. Create libname for folder to store permanent SAS dataset  **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA ELR_Antigen ;  set Antigen_temp_ ;   run;


**  7. PROC contents of final dataset  **;
   PROC contents data= ELR_Antigen  varnum ; title1 'ELR_Antigen'; run;




** 8.  Move copy to DASHboard directory **;
/*libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;*/
/**/
/*DATA DASH.TestPositivity ; set Test_Positivity ;*/
/*   KEEP  Lab  Daily_Tests  Daily_Confirmed_only  Positivity  TestDate  ;*/
/*run;*/

