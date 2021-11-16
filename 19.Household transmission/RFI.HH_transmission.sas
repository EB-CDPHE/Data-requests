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



*** Filter data  ***;
***------------***;

DATA CEDRS_filtered;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND
   (  ('01SEP20'd le  ReportedDate  le '01NOV20'd ) OR ('01SEP21'd le  ReportedDate  le '01NOV21'd)  ) 
      AND LiveInInstitution ne 'Yes';

   Keep  ProfileID EventID CountyAssigned  ReportedDate  CaseStatus  Outcome   Age_at_Reported 
         Transmission_Type  LiveInInstitution  ExposureFacilityName  ExposureFacilityType 
         Gender  Homeless  Race  Ethnicity  Outbreak_Associated  Symptomatic  OnsetDate
         CollectionDate   Address:  ;
run;



*** Check completeness of address data ***;
***------------------------------------***;

* Address1 missing *;
   PROC freq data= CEDRS_filtered ;
      where Address1 = '';
      tables Address1 Address2 AddressActual / missing missprint;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=729 obs missing data for Address1 and Address2
 | N=52 obs where Address1='' and Address2 contains data. THEREFORE:
 | FIX:  If Address1='' and Address2^='' then Address1=Address2;
 *--------------------------------------------------------------------*/

   PROC freq data= CEDRS_filtered ;
      where Address1 = '0';
      tables Address1 Address2 AddressActual / missing missprint;
run;
/*---------------------------------------------------------------*
 |FINDINGS:
 | n=46 obs where Address1 = '0' (and Address2 = missing)
 | FIX:  If Address1='0' then Address1=' ';
 *---------------------------------------------------------------*/


* City missing *;
   PROC freq data= CEDRS_filtered ;
      where Address_City = '';
      tables Address1 Address2 AddressActual  Address_City Address_CityActual / missing missprint;
run;
/*----------------------------------------------------------------------------------*
 |FINDINGS:
 | n=465 obs missing data for Address_City, Address_CityActual, and AddressActual
 *----------------------------------------------------------------------------------*/


* County *;
   PROC freq data= CEDRS_filtered ;
      where CountyAssigned = '';
      tables Address1 Address2 AddressActual  Address_City  Address_CityActual  CountyAssigned / missing missprint;
run;
/*---------------------------------------------------*
 |FINDINGS:
 | NO obs have missing data for CountyAssigned
 *--------------------------------------------------*/


* Lat / Long *;
   PROC freq data= CEDRS_filtered ;
      where Address_Latitude = ''  OR  Address_Longitude = '';
      tables Address_Latitude * Address_Longitude  / missing missprint;
run;

/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=7177 obs missing data Address_Latitude and Address_Longitude
 *--------------------------------------------------------------------*/


* Zipcode *;
   PROC freq data= CEDRS_filtered ;
      tables Address_Zipcode / missing missprint;
run;

/*-------------------------------------------------------------------------*
 |FINDINGS:
 | For zipcode with 9 digits need to insert '-'.
 | Then need to create numeric zipcode from first 'word' 
 | Then can use zipcode range (80000 - 81700) to fill in missing State
 *-------------------------------------------------------------------------*/



*** Records by completeness of components of a complete address ***;
***-------------------------------------------------------------***;

   PROC format;
      value $AnyDataFmt
         ' '='Missing data'
         other='Has data' ;       
run;

 * Records with full address *;
   PROC freq data= CEDRS_filtered  order=freq;
      tables Address1 * Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1   Address_City   Address_State   Address_Zipcode $AnyDataFmt.;
run;
/*---------------------------------------------------------------------------------------*
 |FINDINGS:
 | n=178,110 (98%) of records have full address
 | n= 53 obs with address1 data but missing City and 40 of those have State and Zip
 |    Easy fix: Google these street addresses to find City.
 | n= 2703 that have street address and city, but missing State.
 |    Don't use State then for defining Households.
 | Define HH by dup of Address1, City, County fields.
 *---------------------------------------------------------------------------------------*/



*** Edit data  ***;
***------------***;

DATA CEDRS_filtered2;  set CEDRS_filtered;

* impute missing collectiondates *;
   if CollectionDate = . then CollectionDate = ReportedDate;

* clean up Address1 data *;
   if Address1='' and Address2^='' then Address1=Address2; 
   else if Address1='' and AddressActual^='' then Address1=AddressActual;

   if Address1 in ('NO ADDRESS PROVIDED', 'N/A', 'UNK', 'UNKNOWN', '0') then Address1='';

   If Address_City=''  AND  Address2 in ('LOVELAND','WELLINGTON')  then Address_City=Address2; 

* clean up missing city values *;
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
/*   if ProfileID= '' then Address_City='';*/
/*   if ProfileID= '' then Address_City='';*/
/*   if ProfileID= '' then Address_City='';*/
/*   if ProfileID= '' then Address_City='';*/
/*   if ProfileID= '' then Address_City='';*/
/*   if ProfileID= '' then Address_City='';*/
/*   if ProfileID= '' then Address_City='';*/

/*   if (Address_Zipcode in '' AND  Address_State='');*/
/*   if    then Full_Address=1;*/

run;

   PROC contents data=CEDRS_filtered2  varnum; title1 'CEDRS_filtered2'; run;



*** Imputation of missing address data ***;
***------------------------------------***;

** Print out records that have address1 data but missing city **;
   PROC print data= CEDRS_filtered2;
      where Address1 ^= '' AND  Address_City='';
      id ProfileID;
      var Address1   Address_City  Address_State  Address_Zipcode  CountyAssigned ;
      format Address1 $35.  Address_City  $10. ;
run;
/*-----------------------------------------------------------*
 | FINDINGS:
 | n= 41 obs with address1 data but missing City.
 | FIX: Google these street addresses to find City.
 *-----------------------------------------------------------*/


** Print out obs that have Zipcode data but missing State **;
   PROC print data= CEDRS_filtered2;
      where Address_Zipcode ^= '' AND  Address_State='';
      id ProfileID;
      var Address1   Address_City  Address_State  Address_Zipcode  CountyAssigned ;
      format Address1 $35.  Address_City  $20. ;
run;
/*----------------------------------------------------------------*
 | FINDINGS:
 | n= 2706 obs with address1 and ZIP code but missing State.
 |    Could use numeric 5 digit zip code to impute State.
 |    i.e. if Zip code between 80000 and 80700 then State = CO
 |    BUT Zip code data is messy; needs to be cleaned first.
 *----------------------------------------------------------------*/



***  Creation of Household (HH) level dataset  ***;
***--------------------------------------------***;

/*---------------------------------------------------------------------*
 | Use Address1 (street address) to group cases into Household.
 | Use City and County to provde context to Address1 (to be unique).
 *---------------------------------------------------------------------*/

** Number of records with County, City and Address1 **;
   PROC freq data= CEDRS_filtered2  order=freq;
      tables Address1 * Address_City * CountyAssigned / list missing missprint;
      format Address1  Address_City  CountyAssigned $AnyDataFmt.;
run;
/*-----------------------------------------------------------------*
 |FINDINGS:
 |  N=180,991 filtered cases with Address, City, and County data
 *-----------------------------------------------------------------*/


**  Sort filtered cases on address variables to define HH  **;
   proc sort data=CEDRS_filtered2
               out=CEDRS_address1;
      by CountyAssigned  Address_City  address1 ;
run;

** Preview Address1 data **;
   PROC print data= CEDRS_address1(obs=10000);
      where address1 ne '';
      ID ProfileID;
      var address1  Address_City   CountyAssigned;
      format address1 Address_City $25.   ;
run;
/*------------------------------------------------------------------------------------------*
 |FINDINGS:
 | There are several examples of HH's with slightly different values for Address1
 |    For example:
 |    "4037 W 62ND PL"  vs  "4037 W 62ND PL 652563542"
 |    "4237 62ND PL  vs "4237 W 62ND PL"  vs "4237 WEST 62ND PLACE"
 |    " 5005 W 61ST DR"  vs  " 5005 W.61ST.DR."
 |    " 6065 UTICA"  vs  " 6065 UTICA ST"
 |    "6288 NEWTON COURT"  vs  "6288 NEWTON CT"
 |    "2320 HANDOVER ST"  vs  "2320 HANOVER ST"
 |
 |    ALSO:  150 N 19TH AVE (in BRIGHTON) is Adams County Sheriff's Detention Facility.
 |    FIX: Set Live_in_Institution = 'Yes'
 |    Should investigate other addresses that have >10 cases per Address1.
 *--------------------------------------------------------------------------------------------*/


**  Define Age groups  **;
   PROC format;
      value AgeFmt
         0-<5='0-4 yo'
         5-<12='5-11 yo'
         12-<18='12-17 yo'
         18-115='Adult' ;
run;

   PROC freq data= CEDRS_filtered2  ;
      tables Age_at_Reported /  missing missprint;
      format Age_at_Reported AgeFmt.;
run;
/*-----------------------------------------------------------------*
 |FINDINGS:
 | n=17 records where Age is missing and n=1 where age = 120.
 | FIX: Filter records out
 *-----------------------------------------------------------------*/


***  Reduce case-level dataset to HH-level dataset  ***;
***-------------------------------------------------***;
DATA CEDRS_HH ;  set CEDRS_address1;
   by CountyAssigned  Address_City  address1 ;

   if first.Address1 then do;  
      Num_HH=0;  Num_Minors=0;  Num_Toddlers=0;  Num_Kids=0;  Num_Teens=0;  Num_Adults=0; 
   end;

   Num_HH+1;

   if 0 le Age_at_reported < 18 then Num_Minors+1;

   if  0 le Age_at_reported <  5 then Num_Toddlers+1;
   else if  5 le Age_at_reported < 12 then Num_Kids+1;
   else if 12 le Age_at_reported < 18 then Num_Teens+1;
   else if 18 le Age_at_reported le 115 then Num_Adults+1;

   if last.Address1 then output;

   Label
      Num_HH = "Number cases in HH"
      Num_Minors = "Number of cases 0-17 yo"
      Num_Toddlers = "Number of cases 0-4 yo"
      Num_Kids = "Number of cases 5-11 yo"
      Num_Teens = "Number of cases 12-17 yo"
      Num_Adults = "Number of cases 18-115 yo"  ;
run;

*  Contents of HH level dataset *;
   PROC contents data=CEDRS_HH  varnum; title1 'CEDRS_HH'; run;



***  Analyze HH level data  ***;
***-------------------------***;

*  Counts of cases per HH by Age group  *;
   PROC freq data= CEDRS_HH ;
      tables Num_HH  Num_Minors  Num_Toddlers  Num_Kids  Num_Teens  Num_Adults ; 
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
