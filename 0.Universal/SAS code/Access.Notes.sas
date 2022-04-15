/**********************************************************************************************
PROGRAM:   Access.Notes
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.Notes
OUTPUT:		       Notes_read
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

**  2. Create temp SAS dataset from SQL table  **;
DATA Notes; set CEDRS66.Notes; run; 

** Review contents of SAS dataset **;
PROC contents data=Notes  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA Notes_temp;
   length Comment $ 900;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Notes(rename=
                   (ProfileID=tmp_ProfileID 
                    UpdateDate=tmp_UpdateDate
                    CreateDate=tmp_CreateDate )
                  ); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ProfileID = cats(tmp_ProfileID);

* Extract date part of a datetime variable  *;
   UpdateDate = datepart(tmp_UpdateDate);   format UpdateDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);   format CreateDate yymmdd10.;

   DROP tmp_:  ;* Comment;  * Drop Comment variable because it has a length of $1024~~!! This messes up the Shrink macro;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Notes_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Notes_read ;  
/*   length ProfileID $ 9;  */
   set Notes_temp_ ;

/*   format ProfileID $9.;*/
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=Notes_read varnum; title1 'Notes_read'; run;


*** Explore data ***;
***--------------***;

   proc freq data=Notes_read;
      tables NoteID ;
run;
