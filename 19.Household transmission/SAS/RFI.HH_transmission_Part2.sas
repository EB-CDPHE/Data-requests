/**********************************************************************************************
PROGRAM:  RFI.HH_transmission_Part2.sas
AUTHOR:   Eric Bush
CREATED:  November 10, 2021
MODIFIED: February 1, 2022	
PURPOSE:	 Add third time period to HH transmission study: 01JAN22 - 31JAN22 (start of 2nd semester)
INPUT:	 COVID.CEDRS_view_fix	  
OUTPUT:		
***********************************************************************************************/
options ps=50 ls=150 ;     * Landscape pagesize settings *;
options ps=65 ls=110 ;     * Portrait pagesize settings *;

title;  options pageno=1;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname MyGIT 'C:\Users\eabush\Documents\GitHub\Data-requests\0.Universal\Data'; run;

   PROC contents data=COVID.CEDRS_view_fix  varnum ;  title1 'COVID.CEDRS_view_fix';  run;



***  Filter data  ***;
***---------------***;

DATA CEDRS_filtered2;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND
      ('01JAN22'd le  ReportedDate  le '31JAN22'd )  ;

   Keep  ProfileID   CountyAssigned   ReportedDate   Age_at_Reported   CollectionDate   
         LiveInInstitution   Homeless   Outbreak_Associated   Symptomatic  OnsetDate 
         Address:  ;
run;

   PROC contents data=CEDRS_filtered2  varnum ;  title1 'CEDRS_filtered2';  run;


*** Check completeness of date data ***;
***------------------------------------***;

   PROC means data= CEDRS_filtered2  maxdec=0 n nmiss;
      var ReportedDate  CollectionDate ;
run;


*** Check completeness of address data ***;
***------------------------------------***;

options ps=50 ls=150 ;     * Landscape pagesize settings *;
* Chk1.Address1 missing *;
   PROC freq data= CEDRS_filtered2 ;
      where Address1 in ('');
      tables Address1 * Address2  / list missing missprint;
      format Address1 Address2   $35.   ;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=290 obs missing data for Address1 and Address2
 | N=10 obs where Address1='' and Address2 contains data. THEREFORE:
 | FIX:  If Address1='' and Address2^='' then Address1=Address2;
 *--------------------------------------------------------------------*/


* Chk2.Address1 invalid *;
   PROC freq data= CEDRS_filtered2 ;
      where notdigit(substr(Address1,1))=1;    * selects records where first character is NOT a number *;
      tables Address1 * Address2  / list missing missprint;
      format Address1 Address2   $35.   ;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=9 obs where Address1 begins with '*'
 | n=4 obs where Address1 begins with '.'
 | n=7 obs where Address1 begins with 'APT'
 | n=2 obs where Address1 begins with 'BAD ADDRESS'
 | n=13 obs where Address1 begins with 'BLD'
 | n=23 obs where Address1 begins with 'BOX'
 | At least one obs with '@*.com'
 | >1 obs where Address1 = 'COLORADO'
 | >1 obs where Address1 = 'COLORADO SPRINGS', 'DENVER', 'DURANGO', 'EDWARDS', 'FEDERAL HEIGHTS', 'GREENWOOD VILLAGE'
 |                         'LAKEWOOD', 'LONGMONT', 'LONGMOT', 'PUEBLO'
 | >1 obs where Address1 contains instructions, e.g. 'DO NOT' or "DON'T" or 'PLEASE KNOCK' OR 'PLEASE VERIFY ADDRESS'
                           OR 'SEE CONFIDENTIAL ADDRESS' OR 'SEE TEMP ADDRESS', 'UPDATE'
 | n=7 obs where Address1 = 'GENERAL DELIVERY'
 | n=54 where Address1 = 'HOMELESS'
 | n=4 where Address1 = 'HOTEL'
 | n=1 where Address1 = 'INTERSTATE 25'
 | n>0 where Address1 = 'N' or 'N/A' or 'NA' or 'NEED' OR 'NO ADDRESS' OR 'NO REPONSE' OR 'NONE' OR 'NOT PROVIDED'
 |                      OR 'U', 'UKNOWN', 'UN', 'UNDOMICILED', 'UNK', 'UNKNOWN'
 | n=4 obs where Address1 begins with 'X'
 | FIX:  Compress Address1 to remove '*' and '.' 
 | Move data from Address1 to Address2 for 'APT' and 'BLD'
 *--------------------------------------------------------------------*/

* Chk2.1)Address1 invalid *;
   PROC print data= CEDRS_filtered2 ;
      where index(Address1, 'AP')=1;
      id ProfileID;  var Address1 Address2 ;
      format Address1 Address2   $35.   ;
run;


* Chk3.City missing *;
   PROC freq data= CEDRS_filtered2 ;
      where Address_City = '';
      tables Address1 Address2 AddressActual  Address_City Address_CityActual Address_State  / list missing missprint;
      format Address1 Address2   $35. ;
run;
/*----------------------------------------------------------------------------------*
 |FINDINGS:
 | n=119 obs missing data for Address_City, Address_CityActual, and AddressActual
 | Half of these are in CO.  n=15 have data in Address1
 *----------------------------------------------------------------------------------*/

* Chk3.1)City missing BUT have Address data *;
   PROC freq data= CEDRS_filtered2 ;
      where Address_City = ''  AND  Address1 ne '' ;
      tables ProfileID * Address1  *  Address_City  * Address_State * address_zipcode / list missing missprint;
      format Address1 Address2   $35.   Address_City $5.  ;
run;


* Chk4.State *;
   PROC freq data= CEDRS_filtered2 ;
      tables Address_State / missing missprint;
run;
/*----------------------------------------------*
 |FINDINGS:
 | Over 98% of records have State=CO
 | State = missing for n=1879 records 
 *----------------------------------------------*/


* Chk5.County *;
   PROC freq data= CEDRS_filtered2 ;
      where CountyAssigned = '';
      tables Address1 Address2 AddressActual  Address_City  Address_CityActual  CountyAssigned / missing missprint;
run;
/*---------------------------------------------------*
 |FINDINGS:
 | NO obs have missing data for CountyAssigned
 *--------------------------------------------------*/


*** Records by completeness of components of a complete address ***;
***-------------------------------------------------------------***;

   PROC format;
      value $AnyDataFmt
         ' '='Missing data'
         other='Has data' ;       
run;

 * Colorado Records with full address (address1, city, state, county) *;
   PROC freq data= CEDRS_Filtered2  order=freq;
      tables Address1 * Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1   Address_City   Address_State   Address_Zipcode $AnyDataFmt.;
run;



*** Imputation of missing State using Zipcode ***;
***-------------------------------------------***;

   PROC format;
      value $COzip
         '80000' - '81800' = 'CO zip'
         other = 'Non-CO zip' ; 
run;

* Zipcode *;
   PROC freq data= CEDRS_filtered2 ;
      where Address1 ^= '' AND  Address_City ^=''  AND  Address_State='' ;  * <-- FOCUS ON RECORDS WITH ZIP DATA BUT MISSING STATE;
      tables Address_Zipcode / missing missprint;
      format Address_Zipcode  $COzip. ;
run;
/*-----------------------------------------*
 |FINDINGS:
 | n=2 obs with missing Zipcode.
 | All other obs have 5 digit Zipcode
 *-----------------------------------------*/

DATA CEDRS_CO_temp; set CEDRS_filtered2 ;
   if Address_State=''  AND  Address1 ne '' AND Address_City ne '' AND 
      ( Address_Zipcode GE '80000' AND  Address_Zipcode LE '81700' )
      then Address_State='CO' ;
run;

 * Colorado Records with full address (address1, city, state, county) *;
   PROC freq data= CEDRS_CO_temp  order=freq;
      tables Address1 * Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1   Address_City   Address_State   Address_Zipcode $AnyDataFmt.;
run;
/*-----------------------------------------------------------*
 | FINDINGS:
 | 99.7% have complete address data now.
 *-----------------------------------------------------------*/


*** Edit data  ***;
***------------***;

DATA CEDRS_CO2;  set CEDRS_CO_temp;
      where Address_State='CO';

* impute missing collectiondates *;
   if CollectionDate = . then CollectionDate = ReportedDate;

* impute missing Address1 with Address2 or AddressActual *;
   if Address1='' and Address2^='' then Address1=Address2; 
   else if Address1='' and AddressActual^='' then Address1=AddressActual;

* clean Address1 data *;
   Address1 = compress(Address1, "*.");
   if index(Address1, '@')>0 then Address1='';

   if Address1 = '*OCCUPATIONAL HEALTH RECORD ONLY*' then Address1 = Address2;
   if Address1 = '*UPDATE ADDRESS*' then do; Address1 = ''; Address2 = ''; end;

   if ProfileID= '2212669' then do;  Address1 = '6250 PROMENADE DRIVE'; Address2 = 'APT 250';  end;
   if ProfileID= '2122686' then do;  tmp_Address1=Address1; Address1=Address2; Address2= tmp_Address1;  end;
   if ProfileID= '2161377' then do;  tmp_Address1=Address1; Address1=Address2; Address2= tmp_Address1;  end;
   if ProfileID= '2246189' then do;  tmp_Address1=Address1; Address1=Address2; Address2= tmp_Address1;  end;
   if ProfileID= '2180128' then do;  tmp_Address1=Address1; Address1=Address2; Address2= tmp_Address1;  end;
   if ProfileID= '2245978' then do;  tmp_Address1=Address1; Address1=Address2; Address2= tmp_Address1;  end;
   if ProfileID= '2196981' then do;  tmp_Address1=Address1; Address1=Address2; Address2= tmp_Address1;  end;

   if Address1 in ('BAD ADDRESS','BROOMFIELD', 'CASTLE ROCK', 'CENTENNIAL', 'COLORADO',
                  'COLORADO SPRINGS', 'DENVER', 'DURANGO', 'EDWARDS', 'FEDERAL HEIGHTS', 'GREENWOOD VILLAGE',
                  'FT COLLINS', 'LAKEWOOD', 'LONGMONT', 'LONGMOT', 'PUEBLO', 'STEAMBOAT') then 
      Address1='';

   if index(Address1,'DO NOT')>0 then Address1='';
   if index(Address1,"DON'T")>0 then Address1='';

   if Address1 in ('GENERAL DELIVERY', 'N', 'N/A', 'NA', 'NEED', 'NONE', 
                  'U', 'UKNOWN', 'UNDOMICILED', 'UNK', 'UNKNOWN'  ) then 
      Address1='';

   if index(Address1,"HOMELESS")=1 then Address1='';
   if index(Address1,"HOTEL")=1 then Address1='';
   if index(Address1,"INTERSTATE")=1 then Address1='';
   if index(Address1,"JJJ")=1 then Address1='';
   if index(Address1,"LIVES IN VAN")=1 then Address1='';
   if index(Address1,"LIVING INDEPENDENTLY")=1 then Address1='';
   if index(Address1,"NG")=1 then Address1='';
   if index(Address1,"NO ADDRESS")=1 then Address1='';
   if index(Address1,"NONE")=1 then Address1='';
   if index(Address1,"NOT PROVIDED")=1 then Address1='';
   if index(Address1,"PLEASE VERIFY ADDRESS")=1 then Address1='';
   if index(Address1,"REPL")=1 then Address1='';
   if index(Address1,"SAME")=1 then Address1='';
   if index(Address1,"SEE CONFIDENTIAL ADDRESS")=1 then Address1='';
   if index(Address1,"SEE TEMP ADDRESS")=1 then Address1='';
   if index(Address1,"TRANSIENT")=1 then Address1='';
   if index(Address1,"UN")=1 then Address1='';
   if index(Address1,"X")=1 then Address1='';

* complete missing City (using Address1 and Zip) *;
   if ProfileID= '2113234' then Address_City = 'DILLON';
   if ProfileID= '2113395' then Address_City = 'PONCHA SPRINGS';
   if ProfileID= '2119993' then Address_City = 'DENVER';
   if ProfileID= '2122092' then Address_City = 'DENVER';
   if ProfileID= '2130094' then Address_City = 'CARR';
   if ProfileID= '2160865' then Address_City = 'LEADVILLE';
   if ProfileID= '2167809' then DO; Address1='BOX 27'; Address_City = 'WOODY CREEK'; END;
   if ProfileID= '2172955' then Address_City = 'FEDERAL HEIGHTS';
   if ProfileID= '2179737' then DO; Address_City = 'NORWOOD'; Address_State='CO'; END;
   if ProfileID= '2179790' then Address_City = 'GREELEY';
   if ProfileID= '2206140' then DO; Address1='106TH PLACE';  Address_City = 'COMMERCE CITY';  END;
   if ProfileID= '2206143' then Address_City = 'WIGGINS';
   if ProfileID= '2219301' then Address_City = 'HOWARD';
   if ProfileID= '2252046' then Address_City = 'AURORA';


   DROP tmp_Address1 ;

run;


   PROC contents data=CEDRS_CO2  varnum; title1 'CEDRS_CO2'; run;


** Number of Colorado records with County, City and Address1 **;
   PROC freq data= CEDRS_CO2 order=freq;
      tables Address1 * Address_City * CountyAssigned / list missing missprint;
      format Address1  Address_City  CountyAssigned $AnyDataFmt.;
run;
/*---------------------------------------------------------------------------------*
 |FINDINGS:
 |  N=112,140 filtered cases from Colorado with Address, City, and County data
 *---------------------------------------------------------------------------------*/



*** Create Age Groups ***;
***-------------------***;

**  Define Age groups  **;
   PROC format;
      value AgeFmt
         0-<5='Infant'
         5-<12='Kid'
         12-<18='Teen'
         18-115='Adult' 
         other = " " ;
run;

   PROC freq data= CEDRS_CO2  ;
      tables Age_at_Reported /  missing missprint;
      format Age_at_Reported AgeFmt.;
run;
/*----------------------------------------*
 |FINDINGS:
 | n=10 records where Age is missing.
 | n=7 records where Age >115
 | FIX: Filter records out.
 *----------------------------------------*/


*** Define AgeGroup variable                        ***;
*** Filter out records with missing address and age ***;
*** and DROP unnecessary variables                  ***;
***-------------------------------------------------***;

DATA CEDRS_Addresses2;  set CEDRS_CO2;
   where (Address1 ne '')  AND (Address_City ne '')  ;

   AgeGroup = put(Age_at_Reported, AgeFmt.);
   AG = put(Age_at_Reported, AgeFmt1.);

   DROP  Homeless  Address2  Address_CityActual  Address_Zip:
         Address_Latitude  Address_Longitude  Address_Tract2000  ;
run;
/*   proc freq data=CEDRS_Addresses2 ; tables AgeGroup AG; run;*/
   PROC contents data=CEDRS_Addresses2  varnum; title1 'CEDRS_Addresses2'; run;



*** Count Number cases per HH and restrict to HH with 2+ cases ***;
***------------------------------------------------------------***;

**  Sort filtered cases on address variables to define HH  **;
   proc sort data=CEDRS_Addresses2
               out=Address1_sort2;
      by CountyAssigned  Address_City  Address1  CollectionDate ;
run;

** Preview Address1 data **;
   PROC print data= Address1_sort2(obs=10000);
      ID ProfileID;
      var Address1  Address_City   CountyAssigned ;
      format address1 Address_City $25.   ;
run;
/*------------------------------------------------------------------------------------------*
 |FINDINGS:
 | There are several examples of HH's with slightly different values for Address1
 | Should investigate other addresses that have >10 cases per Address1.
 *--------------------------------------------------------------------------------------------*/

DATA CEDRS_HouseHolds2 
      FlagAddress2(keep=CountyAssigned  Address_City  Address1);  
   set Address1_sort2;
   by CountyAssigned  Address_City  Address1 ;

   if first.Address1 then do;  NumCases_HH=0;  Cluster=1;  NumCases_Cluster=0;  Days_since_last_case=0;  end;
   else Days_since_last_case = CollectionDate - lag(CollectionDate);

   NumCases_HH+1;

   if Days_since_last_case >30 then do; Cluster+1;  NumCases_Cluster=0;  Days_since_last_case=0;  end;

   NumCases_Cluster+1;
   Days_since_last_case = CollectionDate - lag(CollectionDate);

   if last.Address1 then do;
      if NumCases_HH=1 then delete;
      if NumCases_HH>10 then output FlagAddress2;
   end;

  output CEDRS_HouseHolds2;
run;
/*   proc print data=FlagAddress; run;*/
/*   proc print data= CEDRS_HouseHolds;  id Address1; var NumCases_HH  Address_City Address_State Age_at_Reported CollectionDate ;  run;*/
/*   proc freq data= CEDRS_HouseHolds noprint; tables CountyAssigned * Address_City * Address1/list out=CountCasesperHH; */
/*   proc freq data= CountCasesperHH; tables count; title1 'Number of cases per HH'; run;*/


*** Then remove HH with more than 10 cases ***;
***----------------------------------------***;

Data CEDRS_HH2; merge FlagAddress2(in=x)  CEDRS_HouseHolds2 ;
   by CountyAssigned  Address_City  Address1 ;
   if x=1 then delete;

   if NumCases_Cluster=1 then Days_between_cases=0;
run;
/*   proc print data= CEDRS_HH;  id ProfileID; var Address1 Address_City Address_State Age_at_Reported CollectionDate ;  run;*/
/*   proc freq data= CEDRS_HH noprint; tables CountyAssigned * Address_City * Address1/list out=CasesperHH; */
/*   proc freq data= CasesperHH; tables count; title1 'Number of cases per HH'; run;*/


*** Transpose data from Case level (tall) to HH level (wide) ***;
***----------------------------------------------------------***;

* transpose CollectionDate *;
   PROC transpose data=CEDRS_HH2  
   out=WideDSN1(drop= _NAME_)
      prefix=CollectDate ; 
      var CollectionDate;          
      by CountyAssigned  Address_City  Address1  Cluster ;
run;
/*   proc print data= WideDSN1;  run;*/

* transpose AG *;
   PROC transpose data=CEDRS_HH2  
   out=WideDSN2(drop= _NAME_)  
      prefix=AG ; 
      var AG;        
      by CountyAssigned  Address_City  Address1 Cluster;
run;
/*   proc print data= WideDSN2; run;*/

* transpose Days_since_last_case *;
   PROC transpose data=CEDRS_HH2  
   out=WideDSN3(drop= _NAME_)
      prefix=DaysBetween ; 
      var Days_since_last_case;          
      by CountyAssigned  Address_City  Address1 Cluster;
run;
/*   proc print data= WideDSN3;  run;*/


***  Creation of Household (HH) level dataset  ***;
***--------------------------------------------***;

* Merge transposed datasets and final counter together *;
DATA HHcases2; merge WideDSN1  WideDSN2  WideDSN3  ;
   by CountyAssigned  Address_City  Address1  Cluster ;

   ARRAY CollectDates{10} CollectDate1-CollectDate10 ;
   ARRAY AGvars{10} AG1-AG10 ;

   do i = 1 to 10;
           if year(RptDates{i}) = 2022 then AGvars{i} = lowcase(AGvars{i}) ;
      else if year(RptDates{i}) = 2021 then AGvars{i} = upcase(AGvars{i}) ;
   end;

   AG=cats(AG1,AG2,AG3,AG4,AG5,AG6,AG7,AG8,AG9,AG10);

   JAN22_AG=compress(AG, 'IKTA');
   Fall21_AG=compress(AG, 'ikta');

   if findc(JAN22_AG,'ikt')>0 then AnyKids22=1;  else if JAN22_AG=''  then AnyKids22=.; else AnyKids22=0;
   if findc(Fall21_AG,'IKT')>0 then AnyKids21=1; else if Fall21_AG='' then AnyKids21=.; else AnyKids21=0;

   DROP i  AG1 AG2 AG3 AG4 AG5 AG6 AG7 AG8 AG9 AG10 ;

* ADD variables to analyze *;
   HHcases22 = countc(AG, 'ikta');
   HHcases21 = countc(AG, 'IKTA');
   HHcasesTotal = sum(HHcases22, HHcases21) ;

   HHaddcases22 = HHcases22-1;
   HHaddcases21 = HHcases21-1;

   ARRAY DayVars{9} DaysBetween2-DaysBetween10 ;
   MeanTime2Spread= mean(of DayVars{*});

run;

   PROC contents data=HHcases2  varnum; title1 'HHcases2'; run;

** To get the number of clusters per HH **;
/*   proc freq data= HHcases noprint; tables CountyAssigned * Address_City * Address1  /list out=CountClustersperHH; */
/*   proc freq data= CountClustersperHH; tables count; title1 'Number of clusters per HH'; run;*/



***  Analyze HH level data  ***;
***-------------------------***;

** Number of HH with 1+ case in time period 1, 2, and 1&2. **;
   PROC SQL;
      select count(*) as NumHH22
      from
         (select distinct CountyAssigned, Address_City, Address1
      from HHcases2 where HHcases22>0 );
quit;

   PROC SQL;
      select count(*) as NumHH21
      from
         (select distinct CountyAssigned, Address_City, Address1
      from HHcases2 where HHcases21>0 );
quit;

   PROC SQL;
      select count(*) as NumHH
      from
         (select distinct CountyAssigned, Address_City, Address1
      from HHcases2 );
quit;


** Number of clusters by time period **;
   PROC means data=HHcases2 n sum maxdec=0 ;  where HHcases22>0;    var  Cluster HHcases22 ;  run;
   PROC means data=HHcases2 n sum maxdec=0 ;  where HHcases21>0;    var  Cluster HHcases21 ;  run;
   PROC means data=HHcases2 n sum maxdec=0 ;  where HHcasesTotal>0; var  Cluster HHcasesTotal ;  run;


** Number of clusters per HH by time period **;
/*   PROC freq data=HHcases noprint ; */
/*      where year(ReportedDate1)=2020;*/
/*      tables CountyAssigned * Address_City * Address1  / list out=ClusterPerHH20;*/
/*   proc print data= ClusterPerHH20; run;*/
/*   PROC freq data= ClusterPerHH20;  tables Count;  run;*/


/*   PROC freq data=HHcases noprint ; */
/*      where year(ReportedDate1)=2021;*/
/*      tables CountyAssigned * Address_City * Address1  / list out=ClusterPerHH21;*/
/*   PROC freq data= ClusterPerHH21; tables Count; run;*/


/*   PROC freq data=HHcases noprint ; */
/*      tables CountyAssigned * Address_City * Address1  / list out=ClusterPerHH;*/
/*   PROC freq data= ClusterPerHH; tables Count; run;*/


** Distribution of FULL list of HH cases involved in time period 1 and 2  **;
   PROC freq data=HHcases2 ;
      where JAN22_AG ne '';
      tables JAN22_AG    /  missing missprint ;
run;
/*   PROC freq data=HHcases ;*/
/*      where Fall21_AG ne '';*/
/*      tables Fall21_AG    /  missing missprint ;*/
/*run;*/


** Distribution of FIRST CASE per AG's involved in time period 1 and 2  (ALL HH) **;
   PROC freq data=HHcases2 ;
      where JAN22_AG ne '';
      tables JAN22_AG    /  missing missprint ;
      format JAN22_AG $1.;
run;
/*   PROC freq data=HHcases ;*/
/*      where Fall21_AG ne '';*/
/*      tables Fall21_AG    /  missing missprint ;*/
/*      format Fall21_AG $1.;*/
/*run;*/


** FOR HH with cases in minors:  Distribution of FIRST CASE per AG's involved in time period 1 and 2  **;
   PROC freq data=HHcases2 ;
      tables AnyKids22 AnyKids21 ;
run;

   PROC freq data=HHcases2 ;
      where JAN22_AG ne ''  AND  AnyKids22=1;
      tables JAN22_AG    /  missing missprint ;
      format JAN22_AG $1.;
run;
/*   PROC freq data=HHcases ;*/
/*      where Fall21_AG ne ''  AND  AnyKids21=1;*/
/*      tables Fall21_AG    /  missing missprint ;*/
/*      format Fall21_AG $1.;*/
/*run;*/


** Average number of cases in clusters by age group of index cases **;
   PROC means data=HHcases2 mean max  maxdec=2 ;
      where JAN22_AG ne '';
      class JAN22_AG ;
      format JAN22_AG $1.;
      var HHaddcases22;
run;

/*   PROC means data=HHcases mean max  maxdec=2 ;*/
/*      where Fall21_AG ne '';*/
/*      class Fall21_AG ;*/
/*      format Fall21_AG $1.;*/
/*      var HHaddcases21;*/
/*run;*/
 

** Average time between index cases and next case by age group of index case **;
   PROC means data=HHcases2 mean range  maxdec=2 ;
      where JAN22_AG ne '';
      class JAN22_AG ;
      format JAN22_AG $1.;
      var DaysBetween2;
run;

/*   PROC means data=HHcases2 mean range  maxdec=2 ;*/
/*      where Fall21_AG ne '';*/
/*      class Fall21_AG ;*/
/*      format Fall21_AG $1.;*/
/*      var DaysBetween2;*/
/*run;*/


** Average time between all cases in cluster by age group of index case **;
   PROC means data=HHcases2 mean range  maxdec=2 ;
      where JAN22_AG ne '';
      class JAN22_AG ;
      format JAN22_AG $1.;
      var MeanTime2Spread;
run;

/*   PROC means data=HHcases mean range  maxdec=2 ;*/
/*      where Fall21_AG ne '';*/
/*      class Fall21_AG ;*/
/*      format Fall21_AG $1.;*/
/*      var MeanTime2Spread;*/
/*run;*/





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
