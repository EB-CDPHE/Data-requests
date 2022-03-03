
/**********************************************************************************************
PROGRAM:    Access.COPHS
AUTHOR:		Eric Bush
CREATED:	   June 22, 2021
MODIFIED:   081021: redirect to COPHS_tidy table and add code for new vaccination variables
            071921: Update per other RFI patterns for SAS programs. Move access and check programs to parent directory.	
PURPOSE:	   Connect to dphe144 "hospital" and create associated SAS dataset.
            The main changes are to convert date fields to true SAS date variables AND
            to shrink character variables to smallest possible size.
INPUT:		Hosp144.COPHS_tidy
OUTPUT:		        COPHS_read
***********************************************************************************************/

/*________________________________________________________________________________________________________*
 | What this program does:
 | 1. Define library to access COPHS database on Hosp144 server using ODBC
 | 2. Create temporary SAS dataset from COPHS data table in the Hospital schema and report findings
 | 3. Use Proc Freq (first time accessing data table) to learn format of date variables
 | 4. Modify SAS dataset per Findings
 |      a) MR_Number, a character variable, is primary key.
 |      b) EventID is numeric and should be converted to char var
 |      c) Convert temporary character var for each date field to a date var
 | 5. Shrink character variables in data set to shortest possible length (based on longest value)
 | 6. Define library to store permanent SAS dataset
 | 7. Rename "shrunken" SAS dataset (by removing underscore added by macro)
 | 8. PROC contents of final dataset
 *________________________________________________________________________________________________________*/

** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME Hosp144    ODBC  dsn='COVID19' schema=hospital;  run;
 

** 2. Read in the first 50 records to create sample SAS dataset **;
DATA COPHS; set Hosp144.COPHS_tidy; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=COPHS  varnum ;  run;    

/*________________________________________________________________________________________________*
 | FINDINGS:                
 |  EventID is numeric instead of character variables.    
 |    --> Create temp version and convert to character variable prior to running SHRINK macro.     
 |  The primary ID var is MR_Number, which is already a character variable.    
 |  Several date vars that are a character variables are dumped into PROC freq to determine format 
 |    --> Convert these to actual date variables.
 *________________________________________________________________________________________________*/


** 3. determine format of dates in the char vars **;
/*   PROC freq data=COPHS ;*/
/*      tables Hospital_Admission_Date___MM_DD_*/
/*             ICU_Admission_Date___MM_DD_YYYY_*/
/*             DOB__MM_DD_YYYY_*/
/*             Positive_COVID_19_Test_Date*/
/*             Discharge_Transfer__Death_Date__*/
/*             Last_Day_in_ICU_During_Admission  ;  * date fields;*/
/*      tables UTD Partial Breakthrough PartialOnly Vaccine_received CO ;*/
/*run;*/

** 3.a) explore obs with bad date value **;
/*   proc print data= COPHS;*/
/*   where MR_Number='228438';*/
/*   var MR_Number Discharge_Transfer__Death_Date__ ;*/
/*   run;*/
* --> value will get set to missing *;

** 3.b) explore obs with bad pos test date value **;
/*   proc print data= COPHS;*/
/*   where MR_Number='4172848';*/
/*   id MR_Number; var  DOB gender Hospital_Admission_Date Positive_COVID_19_Test_Date ;*/
/*   format  MR_Number  DOB  gender  Hospital_Admission_Date  Positive_COVID_19_Test_Date $10. ;*/
/*   run;*/
* --> change year part from 0201 to 2021 below  *;


** 4. Modify SAS dataset per Findings **;
DATA COPHS_temp;  
   set COPHS(rename= 
            (UTD=tmp_UTD
             DOB=tmp_dob
             EventID=tmp_EventID
             Date_Added=tmp_DateAdded
             )); 
/*   if MR_Number='4172848' AND Hospital_Admission_Date = '2021-07-01' then Positive_COVID_19_Test_Date = '2021-07-02' ;*/

* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);

*  Extract date part of date-time variable *;
   Date_Added = datepart(tmp_DateAdded);   format Date_Added mmddyy10.;

* Convert temporary character var for each date field to a date var *;
   Hosp_Admission    = input(Hospital_Admission_Date, yymmdd10.);          format Hosp_Admission mmddyy10.;
   ICU_Admission     = input(ICU_Admission_Date, yymmdd10.);               format ICU_Admission mmddyy10.;
   DOB               = input(tmp_dob, yymmdd10.);                          format DOB mmddyy10.;
   Positive_Test     = input(Positive_COVID_19_Test_Date, yymmdd10.);      format Positive_Test mmddyy10.;
   Date_left_facility= input(Discharge_Transfer_Death_Date, yymmdd10.);    format Date_left_facility mmddyy10.;
   Last_Day_in_ICU   = input(Last_Day_in_ICU_During_Admission, yymmdd10.); format Last_Day_in_ICU mmddyy10.;
   UTD               = input(tmp_UTD, yymmdd10.);                          format UTD mmddyy10.;
   Date_first_Vx     = input(Partial, yymmdd10.);                          format Date_first_Vx mmddyy10.;

   Label
      Hosp_Admission   = 'Hospital Admission date'
      ICU_Admission    = 'ICU Admission date'
      DOB              = 'Date of Birth'
      Positive_Test    = 'Positive COVID19 test date'
      Date_left_facility = 'Date of Discharge, Transfer, or Death'
      Last_Day_in_ICU  = 'Last day in ICU during Admission' 
      UTD              = 'Date of last vaccination'
      Date_first_Vx    = 'Date of first vaccination'  
      COPHS_Breakthrough = 'Hospitalized breakthrough case'
      COPHS_PartialOnly      = 'Partially vaccinated at Pos Test date'
      Vaccine_Received = 'Type of COVID vaccine received'
      CO               = 'Colorado resident'  ;

   DROP 
      Hospital_Admission_Date 
      ICU_Admission_Date
      Positive_COVID_19_Test_Date
      Discharge_Transfer_Death_Date
      Last_Day_in_ICU_During_Admission  
      Partial
      tmp_:  ;

   * Remove obs with missing Hospital Admit date AND have bogus data (i.e. Positive_Test in 1900) *;
   if Hosp_Admission=.  AND .< year(Positive_Test) <1901 then DELETE;


run;


** 5. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(COPHS_temp)

*  --> output dsn will be "COPHS_temp_"   (NOTE: underscore appended to end of dsn) ;


** 6. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 7. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COPHS_read ; set COPHS_temp_ ;
run;


**  8. PROC contents of final dataset  **;
   PROC contents data= COPHS_read varnum;  title1 'COPHS_read'; run;


