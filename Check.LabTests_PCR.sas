/**********************************************************************************************
PROGRAM:  Check.LabTests_PCR
AUTHOR:   Eric Bush
CREATED:  August 20, 2021
MODIFIED: 
PURPOSE:	 After a SQL data table has been read using Access.LabTests, this program can be used to explore the SAS dataset
INPUT:	 LabTests_read
OUTPUT:	 printed output
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;



** 3. Modify SAS dataset per Findings **;
DATA LabTests_PCR; 
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set LabTests(rename=
                (EventID    = tmp_EventID
                 ResultDate = tmp_ResultDate
                 CreateDate = tmp_CreateDate
                 UpdateDate = tmp_UpdateDate)
                 );     

* restrict to just COVID sequencing results *;
   where TestTypeID in (436, 437)  ;
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   EventID = cats(tmp_EventID);

* Convert temporary character var for each date field to a date var *;
/*   OnsetDate = input(tmp_onsetdate, yymmdd10.); format OnsetDate yymmdd10.;*/

* Extract date part of a datetime variable  *;
   ResultDate = datepart(tmp_ResultDate);   format ResultDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);   format CreateDate yymmdd10.;
   UpdateDate = datepart(tmp_UpdateDate);   format UpdateDate yymmdd10.;

   DROP tmp_: ;
/*   Keep EventID  CreatedDate;*/
run;

   PROC contents data=LabTests_PCR varnum ; title1 'LabTests_PCR'; run;


** 4. Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(LabTests_PCR)



** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA LabTests_PCR_read ; set LabTests_PCR_;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=LabTests_PCR_read  varnum ;  title1 'LabTests_PCR_read';  run;



   PROC print data=LabTests_PCR_read ;
   id EventID;
   var LabSpecimenID LabID  TestTypeID TestType ResultID ResultText  QuantitativeResult CreateDate;
run;














