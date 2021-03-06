/**********************************************************************************************
PROGRAM:    Access.LabTests_TT434     
AUTHOR:		Eric Bush
CREATED:	   September 1, 2021
MODIFIED:   
PURPOSE:	   Connect to CEDRS backend (dphe66) to access LabTests
INPUT:		dbo66.zDSI_LabTests  WHERE TestTypeID= 434 (TestType = 'Other Molecular Assay')
OUTPUT:		      Lab_TT434_read
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/


** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;         * <--  Changed BK's libname ; 


** 2. Read in the SQL table to create initial SAS dataset **;
DATA LabTests; set CEDRS66.zDSI_LabTests; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=LabTests  varnum ; title1 'CEDRS66.zDSI_LabTests';  run;  

**  Review different test types related to COVID testing  **;
/*   PROC freq data = LabTests;*/
/*      tables TestTypeID * TestType /list; */
/*run;*/

/*   PROC print data= LabTests; */
/*      where TestType = 'RT-PCR'; */
/*      var TestTypeID TestType ResultID ResultText QuantitativeResult; */
/*run;*/

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    EventID is a numeric instead of character variable.    
 |    (Convert to character prior to running SHRINK macro.)    
 |    CreatedDate is a date-time variable. Extract date part and create date variable.
 |    Character vars have length and format of $255. Keep just the two new variables plus ICU.
 |
 |NOTE:  
 | ** TestTypeID=229 for TestType = 'RT-PCR'
 | ** TestTypeID=434 for TestType = 'Other Molecular Assay'
 | ** TestTypeID=435 for TestType = 'Antigen for COVID-19'
 | ** TestTypeID=436 for TestType = 'Variant of public health concern'
 | ** TestTypeID=437 for TestType = 'COVID-19 Variant Type'
 | ** TestTypeID=439 for TestType = ' At-home Antigen'
 *________________________________________________________________________________________________*/

** Calculate frequency of various test types related to COVID **;
/*   PROC freq data = LabTests;*/
/*      where TestTypeID in (229, 435, 436, 437) ;*/
/*      tables TestTypeID * TestType /list; */
/*      format TestType $35.;*/
/*run;*/


** 3. Modify SAS dataset per Findings **;
DATA TT434_temp; 
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set LabTests(rename=
                (EventID    = tmp_EventID
                 ResultDate = tmp_ResultDate
                 CreateDate = tmp_CreateDate
                 UpdateDate = tmp_UpdateDate)
                 );     

* restrict to just COVID sequencing results *;
   where TestTypeID = 434 ;
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);

* Convert temporary character var for each date field to a date var *;
/*   OnsetDate = input(tmp_onsetdate, yymmdd10.); format OnsetDate yymmdd10.;*/

* Extract date part of a datetime variable  *;
   ResultDate = datepart(tmp_ResultDate);   format ResultDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);   format CreateDate yymmdd10.;
   UpdateDate = datepart(tmp_UpdateDate);   format UpdateDate yymmdd10.;

   DROP tmp_: ;

   Label LabID = "Lab's Test ID";
run;


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(TT434_temp)



** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Lab_TT434_read ; set TT434_temp_;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=Lab_TT434_read  varnum ;  title1 'Lab_TT434_read';  run;


