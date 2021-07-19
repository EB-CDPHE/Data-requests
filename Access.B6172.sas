/**********************************************************************************************
PROGRAM: Access.B6172
AUTHOR:  Eric Bush
CREATED: July 15, 2021
MODIFIED:	070121:  Modified where clause to include Delta Plus variants
            063021:  Modify to be consistent with READ.SQL_DSN template
PURPOSE:	Connect to CEDRS backend and create associated SAS dataset
INPUT:		SQL code from Bre joins data tables from CEDRS Warehouse:  CEDRS66.zDSI_Profiles, CEDRS66.zDSI_Events, CEDRS66.zDSI_LabTests 
            the join creates -->  work.denominator_ALL_B6172
OUTPUT:		COVID.B6172_read
***********************************************************************************************/

/*--------------------------------------------------------------------------------------------------*
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
 *---------------------------------------------------------------------------------------------------*/


** 1. Libname to access COVID19 database on dbo144 server using ODBC **;
LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;         * <--  Changed BK's libname ; 


** 2. Read data table to create SAS dataset **;

** Here is BK's SQL code to join variant data with other tables **
** I modified this by deleting the last phrase of the where statement: **
** DELETED -->   and e.countyassigned like '%Mesa%'    <-- DELETED **;

****************************************;
*BKawasaki 6-8-2021*********************;
*B.1.617.2s in Mesa County**************;  * <-- I removed this restriction from the where clause to get variants for ALL of Colorado;
****************************************;

		/*** B.1.617.2s in Colorado ***/
PROC SQL;
   create table denominator_ALL_B6172
   as select distinct   d.ProfileID, d.LastName, d.FirstName, d.MiddleName, d.Birthdate/*, input(d.BirthDate, anydtdtm.) as DOBdate fortmat=dtdate9.*/, d.Gender, 
                        e.EventID, e.Disease, e.EventStatus, e.countyassigned, e.EntryMethod, e.ReportedDate, e.Age, e.AgeType, e.Outcome, 
                        l.TestType, l.ResultText, l.QuantitativeResult, l.ResultDate, l.CreateDate
	
	from CEDRS66.zDSI_Profiles d
	left join CEDRS66.zDSI_Events e on d.ProfileID = e.ProfileID
	left join CEDRS66.zDSI_LabTests l on e.EventID = l.EventID

	where d.ProfileID ne . and e.Deleted ne 1 and e.EventID ne . and l.TestType='COVID-19 Variant Type' and 
      ( index(l.ResultText,'B.1.617.2')>0   OR   l.QuantitativeResult like '%B.1.617.2%'   OR   index(l.QuantitativeResult,'AY.2')>0 )
      and e.disease ='COVID-19' and e.EventStatus in ('Probable','Confirmed')  

	group by e.EventID  ;
	quit;


 ** Review contents of SAS dataset **;
  PROC contents data= denominator_ALL_B6172;  run;


** 3. Modify SAS dataset per Findings **;
DATA B6172_temp; 
   set denominator_ALL_B6172(rename=
                              (ProfileID=tmp_ProfileID 
                               EventID=tmp_EventID
                               BirthDate=tmp_BirthDate
                               ReportedDate=tmp_ReportedDate
                               CreateDate=tmp_CreateDate
                               ResultDate=tmp_ResultDate
                             ));
 
* change ID variables from numeric to character variable ;
   ProfileID = cats(tmp_ProfileID);      
   EventID = cats(tmp_EventID);

* change variables with dates from character var to true date variable ;
   BirthDate     = input(tmp_BirthDate, yymmdd10.);      format BirthDate yymmdd10.;

* extract date part of datetime variable;
   CreateDate     = datepart(tmp_CreateDate);    format CreateDate yymmdd10.;
   ReportedDate   = datepart(tmp_ReportedDate);  format ReportedDate yymmdd10.;
   ResultDate     = datepart(tmp_ResultDate);    format ResultDate yymmdd10.;

   drop  tmp_: ;
run;
/*      proc contents data= B6172;  run;*/
/*      proc print data= B6172; var reported_date; format reported_date mmddyy10. ;    run;*/


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(B6172_temp)


 ** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COVID.B6172_read ; set B6172_temp_;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=COVID.B6172_read varnum; run;
