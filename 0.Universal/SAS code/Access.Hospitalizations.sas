/**********************************************************************************************
PROGRAM:   Access.Hospitalizations
AUTHOR:    Eric Bush
CREATED:   April 11, 2022
MODIFIED:  Created from Access.GetProfiles.sas
PURPOSE:   Access SQL table on Events
INPUT:	  CEDRS66.GetProfiles
OUTPUT:		       GetProfiles_read
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
DATA Hospitalizations; set CEDRS66.Hospitalizations; 
run; 

** Review contents of SAS dataset **;
PROC contents data=Hospitalizations  varnum ;  run;   


** 3. Modify SAS dataset per Findings **;
DATA Hospitalizations_temp;
* rename vars in set statement using "tmp_" prefix to preserve var name in output dataset;
   set Hospitalizations(rename=
                   (ProfileID=tmp_ProfileID 
                    AdmissionDate=tmp_AdmissionDate
                    DischargeDate=tmp_DischargeDate
                    TransferDate=tmp_TransferDate
                    UpdatedDate=tmp_UpdatedDate
                    CreateDate=tmp_CreateDate )
                  ); 
 
* Convert temporary numeric ID variable character ID var using the CATS function *;
   ProfileID = cats(tmp_ProfileID);

* Extract date part of a datetime variable  *;
   AdmissionDate = datepart(tmp_AdmissionDate);   format AdmissionDate yymmdd10.;
   DischargeDate = datepart(tmp_DischargeDate);   format DischargeDate yymmdd10.;
   TransferDate = datepart(tmp_TransferDate);   format TransferDate yymmdd10.;
   UpdatedDate = datepart(tmp_UpdatedDate);   format UpdatedDate yymmdd10.;
   CreateDate = datepart(tmp_CreateDate);   format CreateDate yymmdd10.;

   DROP tmp_:  ;
run;


** 4. Shrink character variables in data set to shortest possible length (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

 %shrink(Hospitalizations_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;
DATA Hospitalizations_read ;   set Hospitalizations_temp_ ;
run;

**  7. PROC contents of final dataset  **;
   PROC contents data=Hospitalizations_read varnum; title1 'Hospitalizations_read'; run;
