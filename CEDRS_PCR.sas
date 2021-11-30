/**********************************************************************************************
PROGRAM:  CEDRS_PCR.sas
AUTHOR:   Eric Bush
CREATED:  November 29, 2021
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;

*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA CEDRS_fix;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL' ;
   Keep ProfileID  EventID  CountyAssigned  ReportedDate  CaseStatus  Outcome 
      Age_at_Reported  Gender  Hospitalized  Reinfection  Breakthrough  CollectionDate   ;
run;

   PROC contents data=CEDRS_fix  varnum; title1 'CEDRS_fix'; run;



***  Extract code from Access.LabTests_TT229.sas  ***;
***-----------------------------------------------***;

** 1. Libname to access COVID19 database on dbo144 server using ODBC **;
LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;         * <--  Changed BK's libname ; 

**  2. Review contents of SAS dataset  **;
DATA LabTests; set CEDRS66.zDSI_LabTests; run;    * <-- for building code add (obs=50) ;

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    EventID is a numeric instead of character variable.    
 |    -->(Convert to character prior to running SHRINK macro.)    
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

** 3. Modify SAS dataset per Findings **;
DATA TT229_temp; 
* rename vars in set statement using "tmp_" prefix to preserve original var name in output dataset;
   set LabTests(rename=
                (EventID    = tmp_EventID
                 ResultDate = tmp_ResultDate
                 CreateDate = tmp_CreateDate
                 UpdateDate = tmp_UpdateDate)
                 );     

* restrict to just RT-PCR results *;
   where TestTypeID = 229 ;
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);

* Extract date part of a datetime variable  *;
   ResultDate = datepart(tmp_ResultDate);   format ResultDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);   format CreateDate yymmdd10.;
   UpdateDate = datepart(tmp_UpdateDate);   format UpdateDate yymmdd10.;

   DROP tmp_: ;

   Label LabID = "Lab's Test ID";
run;

**  4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(TT229_temp)

**  5. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Lab_TT229_read ; set TT229_temp_;
run;

**  6. PROC contents of final FULL dataset  **;
   PROC contents data=Lab_TT229_read  varnum ;  title1 'Lab_TT229_read';  run;


**  7. Create list of unique EventID's from CEDRS data  **;
   PROC freq data = COVID.CEDRS_view_fix  noprint;
      tables  EventID / out=CEDRS_Events ;
run;

**  8. Reduce dataset to only records where EventID is in CEDRS  **;
  PROC sort data= CEDRS_Events 
              out= CEDRS_Events_sort;
      by EventID;
run;
   PROC sort data= Lab_TT229_read 
               out= Lab_TT229_sort;
      by EventID LabSpecimenID;
run;  

DATA Lab_TT229_reduced(DROP=COUNT PERCENT);
   merge Lab_TT229_sort(in=p)   CEDRS_Events_sort(in=c) ;
   by EventID ;

   if p=1 AND c=1;
run;

**  9. PROC contents of final REDUCED dataset  **;
  PROC contents data=Lab_TT229_reduced; title1 'Lab_TT229_reduced';  run;



***  Extract code from Fix.LabTests_TT229.sas  ***;
***--------------------------------------------***;

** STEP 1:  De-duplicate records with two LabTest results per Specimen that have identical values in FOUR variables **;
   proc sort data= Lab_TT229_reduced  
              out= TT229_DeDup4  NODUPKEY ;  
      by LabSpecimenID  ResultID  ResultDate  descending CreateDate  ; 
run;

** STEP 2:  De-duplicate records with two LabTest results per Specimen that have identical values in THREE variables **;
** Keeps record with most recent (latest) CreateDate **;
   proc sort data= TT229_DeDup4  
              out= TT229_DeDup3  NODUPKEY ;  
      by LabSpecimenID  ResultID  ResultDate    ; 
run;

** STEP 3a:  De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables  **;
**          AND ResultDate = .  **;
DATA TT229_DeDup2a ;   
   set TT229_DeDup3;
   by LabSpecimenID ResultID;
* Delete duplicate record where ResultDate = missing *;
   if (first.LabSpecimenID ne last.LabSpecimenID)  AND (first.ResultID ne last.ResultID)  
    AND ResultDate= . then delete ;
run;

** STEP 3b:  De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables  **;
**          AND ResultDate NOT = .  **;
** Keep record with the earlier ResultDate  **;
   proc sort data= TT229_DeDup2a  
              out= TT229_DeDup2  NODUPKEY ;  
      by LabSpecimenID  ResultID    ; 
run;

** STEP 4a:  De-duplicate records with two LabTest results per Specimen that have identical values in ONE variable  **;
**          AND ResultDate = .  **;
DATA TT229_DeDup1a ;   
   set TT229_DeDup2;
   by LabSpecimenID ResultID;

* Delete duplicate record where ResultDate = missing *;
   if (first.LabSpecimenID ne last.LabSpecimenID)  AND ResultDate= . then delete ;
run;

** STEP 4b:  De-duplicate records with two LabTest results per Specimen that have identical values in TWO variables  **;
**          AND ResultDate NOT = .  **;
** Keep record with the earlier ResultDate  **;
   proc sort data= TT229_DeDup1a  
              out= TT229_DeDup1  NODUPKEY ;  
      by LabSpecimenID ; 
run;

** STEP 5:  Fix data errors per findings in Check.LabTests_TT437.sas program  **;
DATA Lab_TT229_temp ;   set TT229_DeDup1 (DROP=  TestBrandID  TestBrand  LegacyTestID  CreatedByID)  ;

* DROP variables not needed for merging  *;
   DROP CreateBy  UpdatedBy  LabID  CreateByID  ;
run;


**  STEP 8:  SORT fixed data for merging  **;
   PROC sort data= Lab_TT229_temp
               out= Lab_TT229_fix;
      by LabSpecimenID EventID;
run;

** STEP 9:  Contents of new dataset with edits **;
   PROC contents data=Lab_TT229_fix  varnum ;  title1 'Lab_TT229_fix';  run;



***  Analysis of PCR results in Lab_TT229_fix  ***;
***--------------------------------------------***;

** completeness of data **;
   PROC means data= Lab_TT229_fix  n nmiss ;
      var LabSpecimenID  ResultID  ResultDate  ELRid ;
run;

** view sample of data **;
  proc print data=Lab_TT229_fix(obs=10000);
   where ELRid ne .   AND  ResultDate ne . ;
   id EventID   ;
   var LabSpecimenID  ResultID  ResultText  ResultDate  ;
  run;


** sort data by EventID **;
   proc sort data=Lab_TT229_fix
              out= TT229_EventID;
      by EventID  ResultDate  CreateDate ;
run;

** keep just the first test result for a person per day **;
Data OnePerDay ; set TT229_EventID ;
   by EventID  ResultDate  ;
   if First.ResultDate=1;
run;

** view sample of data **;
  proc print data=OnePerDay;
/*   where ELRid ne .   AND  ResultDate ne . ;*/
   id EventID   ;
   var LabSpecimenID  ResultID  ResultText  ResultDate  ;
  run;

** check that there are not multiple records per person per day **;
  proc freq data= OnePerDay  noprint ;
   tables EventID*ResultDate / list out=NumPCRsPerDay;
run;
   proc freq data= NumPCRsPerDay;  tables count;  run;




