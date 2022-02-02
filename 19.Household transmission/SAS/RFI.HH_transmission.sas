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

* Correlation of ReportedDate and CollectionDate *;
   PROC means data= COVID.CEDRS_view_fix  ;  var ReportedDate CollectionDate;  run;

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

   Keep  ProfileID   CountyAssigned   ReportedDate   Age_at_Reported   CollectionDate   
         LiveInInstitution   Homeless   Outbreak_Associated   Symptomatic  OnsetDate 
         Address:  ;
run;

   PROC contents data=CEDRS_filtered  varnum ;  title1 'CEDRS_filtered';  run;


*** Check completeness of address data ***;
***------------------------------------***;

* Address1 missing *;
   PROC freq data= CEDRS_filtered ;
/*      where Address1 = '';*/
      tables Address1 Address2 AddressActual / missing missprint;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=776 obs missing data for Address1 and Address2
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

   PROC freq data= CEDRS_filtered ;
      where Address1 in ('NO ADDRESS PROVIDED', 'N/A', 'UNK', 'UNKNOWN');
      tables Address1 Address2 AddressActual / missing missprint;
run;


* City missing *;
   PROC freq data= CEDRS_filtered ;
      where Address_City = '';
      tables Address1 Address2 AddressActual  Address_City Address_CityActual / missing missprint;
run;
/*----------------------------------------------------------------------------------*
 |FINDINGS:
 | n=465 obs missing data for Address_City, Address_CityActual, and AddressActual
 *----------------------------------------------------------------------------------*/

   PROC freq data= CEDRS_filtered ;
      where Address_CityActual = '';
      tables Address1 Address2 AddressActual  Address_City Address_CityActual / missing missprint;
run;


* State *;
   PROC freq data= CEDRS_filtered ;
      tables Address_State / missing missprint;
run;
/*----------------------------------------------*
 |FINDINGS:
 | Over 98% of records have State=CO
 | NOTE: Add to Address Filter
 | N=2992 records where State = missing
 *----------------------------------------------*/


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


*** Records by completeness of components of a complete address ***;
***-------------------------------------------------------------***;

   PROC format;
      value $AnyDataFmt
         ' '='Missing data'
         other='Has data' ;       
run;

 * Colorado Records with full address (address1, city, state, county) *;
   PROC freq data= CEDRS_Filtered  order=freq;
/*      where Address_State='CO';*/
      tables Address1 * Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1   Address_City   Address_State   Address_Zipcode $AnyDataFmt.;
run;
/*---------------------------------------------------------------------------------------*
 |FINDINGS:
 | n= 178,080 (98%) of records have full address
 | n= 55 obs with address1 data but missing City and 49 of those have State or Zip
 |    Easy fix: Google these street addresses to find City.
 | n= 2706 that have street address and city, but missing State.
 |    Don't use State then for defining Households.
 | Define HH by dup of Address1, City, County fields.
 *---------------------------------------------------------------------------------------*/



*** Edit data  ***;
***------------***;

DATA CEDRS_CO;  set CEDRS_filtered;
      where Address_State='CO';

* impute missing collectiondates *;
   if CollectionDate = . then CollectionDate = ReportedDate;

* clean up Address1 data *;
   if Address1='' and Address2^='' then Address1=Address2; 
   else if Address1='' and AddressActual^='' then Address1=AddressActual;

  * same house but one has STREET and the other ST *;
   if ProfileID= '1181098'  then Address_Zipcode = '80443';
   if ProfileID= '1181099'  then do;
      Address_Zipcode='80443';
      Address1='502 B GRANITE ST';
   end;

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

   PROC contents data=CEDRS_CO  varnum; title1 'CEDRS_CO'; run;



*** Imputation of missing address data ***;
***------------------------------------***;

** Print out Colorado records that have address1 data but missing city **;
   PROC print data= CEDRS_CO;
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


** Print out Colorado records that have Zipcode data but missing State **;
   PROC print data= CEDRS_CO;
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


** Number of records with County, City and Address1 **;
   PROC freq data= CEDRS_CO  order=freq;
      tables Address1 * Address_City * CountyAssigned / list missing missprint;
      format Address1  Address_City  CountyAssigned $AnyDataFmt.;
run;
/*-----------------------------------------------------------------*
 |FINDINGS:
 |  N=180,890 filtered cases with Address, City, and County data
 *-----------------------------------------------------------------*/

/*---------------------------------------------------------------------*
 | Filter out cases with missing Address1.
 | Use Address1 (street address) to group cases into Household.
 | Use City and County to provde context to Address1 (to be unique).
 *---------------------------------------------------------------------*/


*** Create Age Groups ***;
***-------------------***;

**  Define Age groups  **;
   PROC format;
      value AgeFmt
         0-<5='Infant'
         5-<12='Kid'
         12-<18='Teen'
         18-115='Adult' ;
run;

   PROC freq data= CEDRS_CO  ;
      tables Age_at_Reported /  missing missprint;
      format Age_at_Reported AgeFmt.;
run;
/*----------------------------------------*
 |FINDINGS:
 | n=17 records where Age is missing.
 | FIX: Filter records out.
 *----------------------------------------*/


*** Define AgeGroup variable                        ***;
*** Filter out records with missing address and age ***;
*** and DROP unnecessary variables                  ***;
***-------------------------------------------------***;
DATA CEDRS_Addresses;  set CEDRS_CO;
   where (Address1 ne '')  AND (Address_City ne '')  AND  (Age_at_Reported ^in (.) ) ;

   AgeGroup = put(Age_at_Reported, AgeFmt.);
   AG = put(Age_at_Reported, AgeFmt1.);

   DROP  LiveInInstitution  Homeless  Address2  Address_CityActual  Address_Zip:
         Address_Latitude  Address_Longitude  Address_Tract2000  ;
run;
/*   proc freq data=CEDRS_Addresses ; tables AgeGroup AG; run;*/
   PROC contents data=CEDRS_Addresses  varnum; title1 'CEDRS_Addresses'; run;



*** Count Number cases per HH and restrict to HH with 2+ cases ***;
***------------------------------------------------------------***;

**  Sort filtered cases on address variables to define HH  **;
   proc sort data=CEDRS_Addresses
               out=Address1_sort;
      by CountyAssigned  Address_City  Address1  ReportedDate ;
run;

** Preview Address1 data **;
   PROC print data= Address1_sort(obs=10000);
      ID ProfileID;
      var Address1  Address_City   CountyAssigned ;
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

DATA CEDRS_HouseHolds 
      FlagAddress(keep=CountyAssigned  Address_City  Address1);  
   set Address1_sort;
   by CountyAssigned  Address_City  Address1 ;

   if first.Address1 then do;  NumCases_HH=0;  Cluster=1;  NumCases_Cluster=0;  Days_since_last_case=0;  end;
   else Days_since_last_case = ReportedDate - lag(ReportedDate);

   NumCases_HH+1;

   if Days_since_last_case >30 then do; Cluster+1;  NumCases_Cluster=0;  Days_since_last_case=0;  end;

   NumCases_Cluster+1;
   Days_since_last_case = ReportedDate - lag(ReportedDate);

   if last.Address1 then do;
      if NumCases_HH=1 then delete;
      if NumCases_HH>10 then output FlagAddress;
   end;

  output CEDRS_HouseHolds;
run;
/*   proc print data=FlagAddress; run;*/
/*   proc print data= CEDRS_HouseHolds;  id Address1; var NumCases_HH  Address_City Address_State Age_at_Reported ReportedDate ;  run;*/
/*   proc freq data= CEDRS_HouseHolds noprint; tables CountyAssigned * Address_City * Address1/list out=CountCasesperHH; */
/*   proc freq data= CountCasesperHH; tables count; title1 'Number of cases per HH'; run;*/


*** Then remove HH with more than 10 cases ***;
***----------------------------------------***;

Data CEDRS_HH; merge FlagAddress(in=x)  CEDRS_HouseHolds ;
   by CountyAssigned  Address_City  Address1 ;
   if x=1 then delete;

   if NumCases_Cluster=1 then Days_between_cases=0;
run;
/*   proc print data= CEDRS_HH;  id ProfileID; var Address1 Address_City Address_State Age_at_Reported ReportedDate ;  run;*/
/*   proc freq data= CEDRS_HH noprint; tables CountyAssigned * Address_City * Address1/list out=CasesperHH; */
/*   proc freq data= CasesperHH; tables count; title1 'Number of cases per HH'; run;*/


*** Transpose data from Case level (tall) to HH level (wide) ***;
***----------------------------------------------------------***;

* transpose ReportedDate *;
   PROC transpose data=CEDRS_HH  
   out=WideDSN1(drop= _NAME_)
      prefix=ReportedDate ; 
      var ReportedDate;          
      by CountyAssigned  Address_City  Address1  Cluster ;
run;
/*   proc print data= WideDSN1;  run;*/

* transpose AG *;
   PROC transpose data=CEDRS_HH  
   out=WideDSN2(drop= _NAME_)  
      prefix=AG ; 
      var AG;        
      by CountyAssigned  Address_City  Address1 Cluster;
run;
/*   proc print data= WideDSN2; run;*/

* transpose Days_since_last_case *;
   PROC transpose data=CEDRS_HH  
   out=WideDSN3(drop= _NAME_)
      prefix=DaysBetween ; 
      var Days_since_last_case;          
      by CountyAssigned  Address_City  Address1 Cluster;
run;
/*   proc print data= WideDSN3;  run;*/


***  Creation of Household (HH) level dataset  ***;
***--------------------------------------------***;

* Merge transposed datasets and final counter together *;
DATA HHcases; merge WideDSN1  WideDSN2  WideDSN3  ;
   by CountyAssigned  Address_City  Address1  Cluster ;

   ARRAY RptDates{10} ReportedDate1-ReportedDate10 ;
   ARRAY AGvars{10} AG1-AG10 ;

   do i = 1 to 10;
           if year(RptDates{i}) = 2020 then AGvars{i} = lowcase(AGvars{i}) ;
      else if year(RptDates{i}) = 2021 then AGvars{i} = upcase(AGvars{i}) ;
   end;

   AG=cats(AG1,AG2,AG3,AG4,AG5,AG6,AG7,AG8,AG9,AG10);

   Fall20_AG=compress(AG, 'IKTA');
   Fall21_AG=compress(AG, 'ikta');

   if findc(Fall20_AG,'ikt')>0 then AnyKids20=1; else if Fall20_AG='' then AnyKids20=.; else AnyKids20=0;
   if findc(Fall21_AG,'IKT')>0 then AnyKids21=1; else if Fall21_AG='' then AnyKids21=.; else AnyKids21=0;

   DROP i  AG1 AG2 AG3 AG4 AG5 AG6 AG7 AG8 AG9 AG10 ;

* ADD variables to analyze *;
   HHcases20 = countc(AG, 'ikta');
   HHcases21 = countc(AG, 'IKTA');
   HHcasesTotal = HHcases20 + HHcases21 ;

   HHaddcases20 = HHcases20-1;
   HHaddcases21 = HHcases21-1;

   ARRAY DayVars{9} DaysBetween2-DaysBetween10 ;
   MeanTime2Spread= mean(of DayVars{*});

run;

   PROC contents data=HHcases  varnum; title1 'HHcases'; run;

** To get the number of clusters per HH **;
/*   proc freq data= HHcases noprint; tables CountyAssigned * Address_City * Address1  /list out=CountClustersperHH; */
/*   proc freq data= CountClustersperHH; tables count; title1 'Number of clusters per HH'; run;*/



***  Analyze HH level data  ***;
***-------------------------***;

** Number of HH with 1+ case in time period 1, 2, and 1&2. **;
   PROC SQL;
      select count(*) as NumHH20
      from
         (select distinct CountyAssigned, Address_City, Address1
      from HHcases where HHcases20>0 );
quit;

   PROC SQL;
      select count(*) as NumHH21
      from
         (select distinct CountyAssigned, Address_City, Address1
      from HHcases where HHcases21>0 );
quit;

   PROC SQL;
      select count(*) as NumHH
      from
         (select distinct CountyAssigned, Address_City, Address1
      from HHcases );
quit;


** Number of clusters by time period **;
   PROC means data=HHcases n ;  where HHcases20>0;    var  Cluster HHcases20 ;  run;
   PROC means data=HHcases n ;  where HHcases21>0;    var  Cluster HHcases21 ;  run;
   PROC means data=HHcases n ;  where HHcasesTotal>0; var  Cluster HHcasesTotal ;  run;


** Number of clusters per HH by time period **;
   PROC freq data=HHcases noprint ; 
      where year(ReportedDate1)=2020;
      tables CountyAssigned * Address_City * Address1  / list out=ClusterPerHH20;
/*   proc print data= ClusterPerHH20; run;*/
   PROC freq data= ClusterPerHH20;  tables Count;  run;


   PROC freq data=HHcases noprint ; 
      where year(ReportedDate1)=2021;
      tables CountyAssigned * Address_City * Address1  / list out=ClusterPerHH21;
   PROC freq data= ClusterPerHH21; tables Count; run;


   PROC freq data=HHcases noprint ; 
      tables CountyAssigned * Address_City * Address1  / list out=ClusterPerHH;
   PROC freq data= ClusterPerHH; tables Count; run;


** Distribution of FULL list of HH cases involved in time period 1 and 2  **;
   PROC freq data=HHcases ;
      where Fall20_AG ne '';
      tables Fall20_AG    /  missing missprint ;
run;
   PROC freq data=HHcases ;
      where Fall21_AG ne '';
      tables Fall21_AG    /  missing missprint ;
run;


** Distribution of FIRST CASE per AG's involved in time period 1 and 2  (ALL HH) **;
   PROC freq data=HHcases ;
      where Fall20_AG ne '';
      tables Fall20_AG    /  missing missprint ;
      format Fall20_AG $1.;
run;
   PROC freq data=HHcases ;
      where Fall21_AG ne '';
      tables Fall21_AG    /  missing missprint ;
      format Fall21_AG $1.;
run;


** FOR HH with cases in minors:  Distribution of FIRST CASE per AG's involved in time period 1 and 2  **;
   PROC freq data=HHcases ;
      tables AnyKids20 AnyKids21 ;
run;

   PROC freq data=HHcases ;
      where Fall20_AG ne ''  AND  AnyKids20=1;
      tables Fall20_AG    /  missing missprint ;
      format Fall20_AG $1.;
run;
   PROC freq data=HHcases ;
      where Fall21_AG ne ''  AND  AnyKids21=1;
      tables Fall21_AG    /  missing missprint ;
      format Fall21_AG $1.;
run;


** Average number of cases in clusters by age group of index cases **;
   PROC means data=HHcases mean max  maxdec=2 ;
      where Fall20_AG ne '';
      class Fall20_AG ;
      format Fall20_AG $1.;
      var HHaddcases20;
run;

   PROC means data=HHcases mean max  maxdec=2 ;
      where Fall21_AG ne '';
      class Fall21_AG ;
      format Fall21_AG $1.;
      var HHaddcases21;
run;
 

** Average time between index cases and next case by age group of index case **;
   PROC means data=HHcases mean range  maxdec=2 ;
      where Fall20_AG ne '';
      class Fall20_AG ;
      format Fall20_AG $1.;
      var DaysBetween2;
run;

   PROC means data=HHcases mean range  maxdec=2 ;
      where Fall21_AG ne '';
      class Fall21_AG ;
      format Fall21_AG $1.;
      var DaysBetween2;
run;


** Average time between all cases in cluster by age group of index case **;
   PROC means data=HHcases mean range  maxdec=2 ;
      where Fall20_AG ne '';
      class Fall20_AG ;
      format Fall20_AG $1.;
      var MeanTime2Spread;
run;

   PROC means data=HHcases mean range  maxdec=2 ;
      where Fall21_AG ne '';
      class Fall21_AG ;
      format Fall21_AG $1.;
      var MeanTime2Spread;
run;





   *** OLD CODE ***;
   ***----------****;

** Distribution of the number of cases in a HH for time period 1, 2, and 1&2 (total). **;
   PROC freq data=HHcases ;
      tables HHcases2020  HHcases2021  HHcasesTotal/  missing missprint ;
      tables HHcases2020 * HHcases2021  / list  missing missprint ;
run;


** Distribution of AG's involved in time period 1, 2, and 1&2 **;
   PROC freq data=HHcases ;
      tables Fall20_AG   Fall21_AG  /  missing missprint ;
run;

** Distribution of which AG was first case in time period 1, 2, and 1&2 **;
   PROC freq data=HHcases ;
      tables Fall20_AG   Fall21_AG  /  missing missprint ;
      format Fall20_AG   Fall21_AG $1.;
run;

** FOR THOSE HH WITH A CASE DURING TP:  Distribution of which AG was first case in time period 1, 2, and 1&2 **;
   PROC freq data=HHcases ;
      where HHcases2020>0;
      tables Fall20_AG   /  missing missprint ;
      format Fall20_AG   Fall21_AG $1.;
run;
   PROC freq data=HHcases ;
      where HHcases2021>0;
      tables Fall21_AG   /  missing missprint ;
      format Fall20_AG   Fall21_AG $1.;
run;


   PROC freq data= HHwide ;
      tables AG / missing missprint  ; 
/*      tables NumCases_HH  AgeGroup1  /list missing missprint  ; */
run;


*  Counts of cases per HH by Age group  *;
   PROC freq data= HHwide ;
/*      tables AgeGroup1 * AgeGroup2 * AgeGroup3 * AgeGroup4 * AgeGroup5 * AgeGroup6 * AgeGroup7 * AgeGroup8 * AgeGroup9 * AgeGroup10    /list missing missprint  ; */
      tables NumCases_HH  AgeGroup1  /list missing missprint  ; 
run;

   PROC freq data= HHwide ;
/*      where AgeGroup1 ne 'Adult';*/
      tables AgeGroup1 * AgeGroup2 * AgeGroup3 * AgeGroup4 * AgeGroup5     /list missing missprint  ; 
/*      tables DaysBetween1 * DaysBetween2 * DaysBetween3 * DaysBetween4 * DaysBetween5 / list missing missprint;*/
/*      tables Age_at_Reported   Num_HH   ; */
run;



/*--------------------------------------*
 |FINDINGS:
 | n=127 HH have >10 cases
 | FIX: filter out HH with >10 cases
 *--------------------------------------*/

proc freq data= CEDRS_HH; 
   where 1 le Num_HH le 10;
tables Num_HH * Num_Minors /missing missprint   ; 
run;


Data HH_cases ;  set CEDRS_HH ;


   PROC freq data= CEDRS_HH ;
      where 
      tables Age_at_Reported   Num_HH  Num_Minors  Num_Toddlers  Num_Kids  Num_Teens  Num_Adults ; 
      format Age_at_Reported  AgeFmt. ;
run;




*** Request 1:  Number of HH with cases in 0-17 yo by two time periods  ***;
***---------------------------------------------------------------------***;
   PROC freq data= CEDRS_HH ;
      tables Age_at_Reported   Num_HH  Num_Minors  Num_Toddlers  Num_Kids  Num_Teens  Num_Adults ; 
      format Age_at_Reported  AgeFmt. ;
run;









***  Access population data  ***;
***--------------------------***;

   PROC means data= COVID.County_Population sum  maxdec=0;
/*      where county = 'MOFFAT';*/
      var population;
run;
