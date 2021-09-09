/**********************************************************************************************
PROGRAM:    Access.Specimens      
AUTHOR:		Eric Bush
CREATED:	   August 30, 2021
MODIFIED:   090921: add code to reduce dataset to EventIDs on CEDRS
PURPOSE:	   Connect to CEDRS backend (dphe66) to access Specimens
INPUT:		dbo66.zDSI_Specimens  
OUTPUT:		      Specimens_read   AND   Specimens_reduced
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
/*options ps=50 ls=150 ;     * Landscape pagesize settings *;*/


** 1. Libname to access [SQL database name] using ODBC **;
LIBNAME CEDRS66  ODBC  dsn='CEDRS' schema=cedrs;  run;         * <--  Changed BK's libname ; 


** 2. Read in the SQL table to create initial SAS dataset **;
DATA Specimens; set CEDRS66.zDSI_Specimens; run;    * <-- for building code add (obs=50) ;

** Review contents of SAS dataset **;
PROC contents data=Specimens  varnum ; title1 'CEDRS66.zDSI_Specimens';  run;  

**  Review different test types related to COVID testing  **;
/*   PROC freq data = Specimens;*/
/*      tables CreatedID * Created / list; */
/*run;*/

/*________________________________________________________________________________________________*
 | FINDINGS:                                                                 
 |    EventID is a numeric instead of character variable.    
 |    (Convert to character prior to running SHRINK macro.)    
 |    CreatedDate is a date-time variable. Extract date part and create date variable.
 |    UpdatedDate is a date-time variable. Extract date part and create date variable.
 |    CollectionDate is a date-time variable. Extract date part and create date variable.
 |    Character vars have length and format of $255. Keep just the two new variables plus ICU.
 |
 *________________________________________________________________________________________________*/

** Calculate frequency of various test types related to COVID **;
/*   PROC freq data = LabTests;*/
/*      where TestTypeID in (229, 435, 436, 437) ;*/
/*      tables TestTypeID * TestType /list; */
/*      format TestType $35.;*/
/*run;*/


** 3. Modify SAS dataset per Findings **;
DATA Specimens_temp; 
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Specimens(rename=
                (EventID    = tmp_EventID
                 CollectionDate = tmp_CollectionDate
                 CreatedDate = tmp_CreatedDate
                 UpdatedDate = tmp_UpdatedDate)
                 );     

* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);

* Extract date part of a datetime variable  *;
   CollectionDate = datepart(tmp_CollectionDate);  format CollectionDate yymmdd10.;
   CreatedDate    = datepart(tmp_CreatedDate);     format CreatedDate     yymmdd10.;
   UpdatedDate    = datepart(tmp_UpdatedDate);     format UpdatedDate    yymmdd10.;

   DROP tmp_: ;

   KEEP LabSpecimenID  EventID  SpecimenTypeID  Specimen  CollectionDate AccessionID  SampleName  
        CreatedDate  CreatedID  Created  UpdatedDate UpdatedID  Updated ;

   Label CreatedDate = "Specimen Create Date "
         UpdatedDate = "Specimen Updated Date " 
         CollectionDate = "Specimen Collection Date "  ;

run;


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Specimens_temp)



** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Specimens_read ; set Specimens_temp_;
run;


**  7. PROC contents of final FULL dataset  **;
   PROC contents data=Specimens_read  varnum ;  title1 'Specimens_read';  run;


**  8. Create list of unique EventID's from CEDRS data  **;
   PROC freq data = COVID.CEDRS_view_fix  noprint;
      tables  EventID / out=CEDRS_Events ;
run;


**  9. Reduce dataset to only records where EventID is in CEDRS  **;
  PROC sort data= CEDRS_Events 
              out= CEDRS_Events_sort;
      by EventID;
run;
   PROC sort data= Specimens_read 
               out= Specimens_sort;
      by EventID LabSpecimenID;
run;  

DATA Specimens_reduced(DROP=COUNT PERCENT);
   merge Specimens_sort(in=s)   CEDRS_Events_sort(in=c) ;
   by EventID ;

   if s=1 AND c=1;
run;


**  10. PROC contents of final REDUCED dataset  **;
  PROC contents data=Specimens_reduced; title1 'Specimens_reduced';  run;
