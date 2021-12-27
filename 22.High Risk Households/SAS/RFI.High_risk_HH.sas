/**********************************************************************************************
PROGRAM:  RFI.High_risk_HH.sas
AUTHOR:   Eric Bush
CREATED:  December 27, 2021
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


*** Filter data  ***;
***------------***;

DATA CEDRS_addresses;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  ;
     * AND LiveInInstitution ne 'Yes';

   Keep  ProfileID   CountyAssigned   ReportedDate   Age_at_Reported   CollectionDate   
         LiveInInstitution   Homeless   Outbreak_Associated   Symptomatic  OnsetDate 
         Address:  ;
run;

   PROC contents data=CEDRS_addresses  varnum ;  title1 'CEDRS_addresses';  run;



*** Edit data  ***;
***------------***;

DATA CEDRS_CO;  set CEDRS_addresses;
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



*** Define AgeGroup variable                        ***;
*** Filter out records with missing address and age ***;
*** and DROP unnecessary variables                  ***;
***-------------------------------------------------***;
DATA CEDRS_Addresses_fix;  set CEDRS_CO;
   where (Address1 ne '')  AND (Address_City ne '') ;* AND  (Age_at_Reported ^in (.) ) ;

/*   AgeGroup = put(Age_at_Reported, AgeFmt.);*/
/*   AG = put(Age_at_Reported, AgeFmt1.);*/

/*   DROP  LiveInInstitution  Homeless  Address2  Address_CityActual  Address_Zip:*/
/*         Address_Latitude  Address_Longitude  Address_Tract2000  ;*/
run;
/*   proc freq data=CEDRS_Addresses ; tables AgeGroup AG; run;*/
   PROC contents data=CEDRS_Addresses_fix  varnum; title1 'CEDRS_Addresses_fix'; run;



*** Count Number cases per HH and restrict to HH with 2+ cases ***;
***------------------------------------------------------------***;

**  Sort filtered cases on address variables to define HH  **;
   proc sort data=CEDRS_Addresses_fix
               out=Address1_sort;
      by CountyAssigned  Address_City  Address1  ReportedDate ;
run;


DATA CEDRS_HouseHolds 
      FlagAddress;  
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



proc print data= FlagAddress; 
   where upcase(LiveInInstitution) ^='YES';
var countyassigned address_city address1 ReportedDate  NumCases_HH LiveInInstitution;
format address1 address_city $25. ;
run;



proc print data= CEDRS_addresses; 
   where address1='8300 SHERIDAN BLVD';
var countyassigned address_city address1 ReportedDate   ;
run;

proc freq data= CEDRS_addresses; 
/*   where address1='8300 SHERIDAN BLVD';*/
tables LiveInInstitution;
run;


*** Create TWO datasets to export to spreadsheet ***;
***----------------------------------------------***;

DATA Institution_NO; set FlagAddress;
   where upcase(LiveInInstitution) ^='YES';
   keep NumCases_HH  LiveInInstitution  countyassigned address_city address1 ReportedDate 
        address2 Address_Zip Address_State Address_Latitude  Address_Longitude  ;
run;
DATA Institution_YES; set FlagAddress;
   where upcase(LiveInInstitution) ='YES';
   keep NumCases_HH  LiveInInstitution  countyassigned address_city address1 ReportedDate 
        address2 Address_Zip Address_State Address_Latitude  Address_Longitude  ;
run;








*** Then KEEP HH with more than 10 cases ***;
***----------------------------------------***;

Data CEDRS_HH; merge FlagAddress(in=x)  CEDRS_HouseHolds ;
   by CountyAssigned  Address_City  Address1 ;
   if x=1 ;

   if NumCases_Cluster=1 then Days_between_cases=0;
run;



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
/*   PROC transpose data=CEDRS_HH  */
/*   out=WideDSN2(drop= _NAME_)  */
/*      prefix=AG ; */
/*      var AG;        */
/*      by CountyAssigned  Address_City  Address1 Cluster;*/
/*run;*/
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
DATA HighRiskHH; merge WideDSN1    WideDSN3  ;
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
   if findc(Fall21_AG,'IKT')>0 then AnyKids21=1; else if Fall20_AG='' then AnyKids21=.; else AnyKids21=0;

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

   PROC contents data=HighRiskHH  varnum; title1 'HighRiskHH'; run;


   PROC print data=FlagAddress  ; 
      var CountyAssigned  Address_City  Address1  ;
      format Address_City  Address1  $25.;
run;


   PROC freq data=HighRiskHH  ; 
/*      where LiveInInstitution='no';*/
      tables liveininstitution ;
/*      tables CountyAssigned * Address_City * Address1  /;*/

run;
