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

   * Fix missing city values *;
   if ProfileID= '1790803' then Address_City='GRAND JUNCTION';
   if ProfileID= '1805723' then Address_City='CANON CITY';
   if ProfileID= '863619' then DO; Address_City='ALAMOSA'; Address_State='CO';  Address_zipcode='81101'; END;
   if ProfileID= '1810320' then Address_City='DENVER';
   if ProfileID= '997479' then Address_City='CANON CITY';
   if ProfileID= '1829366' then Address_City='PUEBLO';
   if ProfileID= '1829683' then Address_City='ELIZABETH';
   if ProfileID= '1830842' then Address_City='ALAMOSA';
   if ProfileID= '1841660' then Address_City='CANON CITY';
   if ProfileID= '1843376' then Address_City='CANON CITY';
   if ProfileID= '1274716.1' then DO;  Address_City='CENTENNIAL';  Address_zipcode='80112';  END; *Arapahoe County Detention Center;
   if ProfileID= '1859049' then Address_City='CANON CITY';
   if ProfileID= '' then Address_City='';
   if ProfileID= '' then Address_City='';
   if ProfileID= '' then Address_City='';
   if ProfileID= '' then Address_City='';
   if ProfileID= '' then Address_City='';
   if ProfileID= '' then Address_City='';
   if ProfileID= '' then Address_City='';

   if (Address_Zipcode in '' AND  Address_State='');
   if then Full_Address=1;

run;

   PROC contents data=CEDRS_HH  varnum; title1 'CEDRS_HH'; run;

   PROC format;
      value AgeFmt
         0-<5='0-4 yo'
         5-<12='5-11 yo'
         12-<18='12-17 yo'
         18-115='Adult' ;

      value $AnyDataFmt
         ' '='Missing data'
         other='Has data' ;       

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

* Address *;
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

* City *;
   PROC freq data= CEDRS_HH ;
      where Address_City = '';
      tables Address1 Address2 AddressActual  Address_City Address_CityActual / missing missprint;
run;

/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=465 obs missing data for Address_City, Address_CityActual, and AddressActual
 *--------------------------------------------------------------------*/


* Lat / Long *;
   PROC freq data= CEDRS_HH ;
      where Address_Latitude = ''  OR  Address_Longitude = '';
      tables Address_Latitude * Address_Longitude  / missing missprint;
run;

/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=7177 obs missing data Address_Latitude and Address_Longitude
 *--------------------------------------------------------------------*/


* Zipcode *;
   PROC freq data= CEDRS_HH ;
      tables Address_Zipcode / missing missprint;
run;

/*-------------------------------------------------------------------------*
 |FINDINGS:
 | For zipcode with 9 digits need to insert '-'.
 | Then need to create numeric zipcode from first 'word' 
 | Then can use zipcode range (80000 - 81700) to fill in missing State
 *-------------------------------------------------------------------------*/

 * Records with full address *;
   PROC freq data= CEDRS_HH  order=freq;
      tables Address1 * Address2 * Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1  Address2  Address_City  Address_State  Address_Zipcode $AnyDataFmt.;
run;

   PROC freq data= CEDRS_HH  order=freq;
      tables Address1 *  Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1   Address_City  Address_State  Address_Zipcode $AnyDataFmt.;
run;

/*-------------------------------------------------*
 |FINDINGS:
 | n=178,110 (98%) of records have full address
 *-------------------------------------------------*/

*** Print out obs that have address1 data but missing city ***;
   PROC print data= CEDRS_HH;
      where Address1 ^= '' AND  Address_City='';
      id ProfileID;
      var Address1   Address_City  Address_State  Address_Zipcode  CountyAssigned ;
      format Address1 $35.  Address_City  $10. ;
run;

*** Print out obs that have Zipcode data but missing State ***;
   PROC print data= CEDRS_HH;
      where Address_Zipcode ^= '' AND  Address_State='';
      id ProfileID;
      var Address1   Address_City  Address_State  Address_Zipcode  CountyAssigned ;
      format Address1 $35.  Address_City  $20. ;
run;



*** PRINT records with complete address ***;
***-------------------------------------***;

   proc sort data=CEDRS_HH
               out=HH_address;
      by CountyAssigned  Address_City  address1 ;
run;

   PROC print data= HH_address(obs=10000);
      where address1 ne '';
      ID ProfileID;
      var CountyAssigned  Address_City  address1 ;
run;

   proc freq data= HH_address noprint;
      where address1 ^= '';
      tables address1 / out=HHcount;
run;
   proc freq data=HHcount; tables count; run;
proc print data=HHcount; where count>1; run;


DATA HH_define ;  set  HH_address;
      by CountyAssigned  Address_City  address1 ;
   if first.Address1 then do;  Num_HH=0; Num_Minors=0;  end;
   Num_HH+1;
   if 0 < Age_at_reported < 18 then Num_Minors+1;
   if last.Address1 then output;
run;

proc freq data= HH_define; 
tables Num_HH  Num_Minors; 
run;

proc freq data= HH_define; 
   where 1 le Num_HH le 20;
tables Num_HH * Num_Minors /missing missprint   ; 
run;





***  Access population data  ***;
***--------------------------***;

   PROC means data= COVID.County_Population sum  maxdec=0;
/*      where county = 'MOFFAT';*/
      var population;
run;
