/**********************************************************************************************
PROGRAM:  RFI.HH_transmission.sas
AUTHOR:   Eric Bush
CREATED:  November 10, 2021
MODIFIED:	
PURPOSE:	  
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=50 ls=150 ;     * Landscape pagesize settings *;
options ps=65 ls=110 ;     * Portrait pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;

   PROC contents data=COVID.CEDRS_view_fix  varnum ;  title1 'COVID.CEDRS_view_fix';  run;


*** Check filter variables ***;
***------------------------***;

* Completeness of ReportedDate *;
   PROC means data= COVID.CEDRS_view_fix  n nmiss;  var ReportedDate CollectionDate;  run;

  * Number of records in time reference period *;
  PROC means data= COVID.CEDRS_view_fix  n nmiss;  
   where ('01SEP20'd le  ReportedDate  le '01NOV20'd ) OR ('01SEP21'd le  ReportedDate  le '01NOV21'd) ;
   var ReportedDate;  
run;

  * Number of records where CountyAssigned = 'INTERNATIONAL' *;
  PROC freq data= COVID.CEDRS_view_fix ;  
   where CountyAssigned = 'INTERNATIONAL' ;
   tables CountyAssigned;  
run;

 * Number of records where LiveInInstitution NE 'Yes' *;
  PROC freq data= COVID.CEDRS_view_fix;  tables LiveInInstitution ;  run;


DATA CEDRS_view_fix;  set COVID.CEDRS_view_fix;
   if CollectionDate = . then CollectionDate = ReportedDate;
run;


*** Create local copy of data for selected variables  ***;
***---------------------------------------------------***;

DATA CEDRS_HH;  set CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND
   (  ('01SEP20'd le  ReportedDate  le '01NOV20'd ) OR ('01SEP21'd le  ReportedDate  le '01NOV21'd)  ) 
      AND LiveInInstitution ne 'Yes';

   Keep  ProfileID EventID CountyAssigned  ReportedDate  CaseStatus  Outcome   Age_at_Reported 
         Transmission_Type  LiveInInstitution  ExposureFacilityName  ExposureFacilityType 
         Gender  Homeless  Race  Ethnicity  Outbreak_Associated  Symptomatic  OnsetDate
         CollectionDate   Address:  ;

   If Address1='' and Address2^='' then Address1=Address2; else
   If Address1='' and AddressActual^='' then Address1=AddressActual;

   IF Address1 in ('NO ADDRESS PROVIDED', 'N/A', 'UNK', 'UNKNOWN') then Address1='';

   If Address_City=''  AND  Address2 in ('LOVELAND','WELLINGTON')  then Address_City=Address2; 

run;

   PROC contents data=CEDRS_HH  varnum; title1 'CEDRS_HH'; run;

   PROC format;
      value AgeFmt
         0-<5='0-4 yo'
         5-<12='5-11 yo'
         12-<18='12-17 yo'
         18-115='Adult' ;
run;


***  Size of sub-population groups  ***;
***---------------------------------***;

   PROC freq data= CEDRS_HH ;
      tables ReportedDate  CollectionDate  Age_at_Reported ;
      format ReportedDate CollectionDate monyy.  Age_at_Reported  AgeFmt. ;
run;

   PROC means data= CEDRS_HH  n nmiss;  var ReportedDate CollectionDate;  run;


*** Check address data for grouping cases into HH ***;
***-----------------------------------------------***;

   PROC freq data= CEDRS_HH ;
      where Address1 = '';
      tables Address1 Address2 AddressActual / missing missprint;
run;

/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=729 obs missing data for Address1 and Address2
 | N=52 obs where Address1='' and Address2 contains data. THEREFORE:
 | FIX:  If Address1='' and Address2^='' then Address1=Address2;
 *--------------------------------------------------------------------*/


   PROC freq data= CEDRS_HH ;
      where Address_City = '';
      tables Address1 Address2 AddressActual  Address_City Address_CityActual / missing missprint;
run;

/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=465 obs missing data for Address_City, Address_CityActual, and AddressActual
 | N=52 obs where Address1='' and Address2 contains data. THEREFORE:
 | FIX:  If Address1='' and Address2^='' then Address1=Address2;
 *--------------------------------------------------------------------*/











***  Access population data  ***;
***--------------------------***;

   PROC means data= COVID.County_Population sum  maxdec=0;
/*      where county = 'MOFFAT';*/
      var population;
run;
