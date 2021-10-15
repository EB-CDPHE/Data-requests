/**********************************************************************************************
PROGRAM:    Access.populations
AUTHOR:		Eric Bush
CREATED:	   June 24, 2021
MODIFIED:   072021: Modify to be consistent with other "Access.*" programs.	
PURPOSE:	   Connect to dphe144 "populations" and create associated SAS dataset.
            Modify "group" variable so that it only contains county name.
INPUT:		dbo144.populations
OUTPUT:		COVID.County_Population
***********************************************************************************************/

/*---------------------------------------------------------------------------------------------------*
 | What this program does:
 | 1. Define library to access COVID19 database on dbo144 server using ODBC
 | 2. Create temporary SAS dataset from Populations SQL table in the dbo schema. Review findings.
 | 3. Modify SAS dataset per Findings
 |    a) Delete Group=Age
 |    b) Delete Group=Gender
 |    c) The only obs that remain are county name so rename Group variable to County
 | 4. Shrink character variables in data set to shortest possible length (based on longest value)
 | 5. Define library to store permanent SAS dataset
 | 6. Rename "shrunken" SAS dataset
 | 7. PROC contents of final dataset
 *---------------------------------------------------------------------------------------------------*/

*** County Population data ***;
***------------------------***;

** 1. Libname to access Populations database on dbo144 server using ODBC **;
LIBNAME dbo144   ODBC  dsn='COVID19' schema=dbo;  run;        


** 2. Review contents of SAS dataset **;
PROC contents data=dbo144.populations  varnum ;  run;    

/*______________________________________________________________________________________________*
 |FINDINGS:
 | Group variable contains 3 different variable values: County name, Age group, and Gender.
 | --> delete Age group and Gender values and rename Group variable to County.
 *______________________________________________________________________________________________*/


** 3. Modify SAS dataset per Findings **;
DATA Pop_temp; set dbo144.populations(Rename=(Group=County)); 
   if index(County,'yrs')>0  then delete;
   if County in ('Female', 'Male') then delete;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Pop_temp)

*  --> output dsn will be "COPHS_temp_"   (NOTE: underscore appended to end of dsn) ;


** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA COVID.County_Population ; set Pop_temp_ ;
run;


**  7. PROC contents of final dataset  **;
   PROC contents data=COVID.County_Population varnum; run;


