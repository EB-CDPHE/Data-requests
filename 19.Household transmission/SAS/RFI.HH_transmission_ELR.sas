/**********************************************************************************************
PROGRAM:  RFI.HH_transmission_ELR.sas
AUTHOR:   Eric Bush
CREATED:  November 10, 2021
MODIFIED: February 1, 2022	
PURPOSE:	  re-do HH transmission for Jan (start of 2nd semester)
INPUT:	 	  
OUTPUT:		
***********************************************************************************************/
options ps=50 ls=150 ;     * Landscape pagesize settings *;
options ps=65 ls=110 ;     * Portrait pagesize settings *;

title;  options pageno=1;

/*-----------------------------------------*
 | Programs to run first:
   1. Access.ELR_Full.sas
 *-----------------------------------------*/

   PROC contents data=ELR_Full varnum ;  title1 'ELR_Full';  run;


*** Filter data to PCR results added since Nov 1, 2021 ***;
***-----------------------------------------------------***;
DATA PCR_Pos_filtered;  set ELR_Full;
   where ('01JAN22'd le  DateAdded  le '31JAN22'd)  AND  covid19negative='N'  ;
run;

options pageno=1;
   PROC contents data=PCR_Pos_filtered  varnum ;  title1 'PCR_Pos_filtered';  run;



   proc freq data= ELR_filtered ;
      tables covid19negative ;
run;

   proc freq data= ELR_filtered  noprint ;
      tables Person_ID * PatientID /list out=Patients_per_POSPerson ;
run;
   proc print data= ; run;

   proc freq data= Patients_per_POSPerson; tables count; run;



** Keep just the first positive PCR for each Person **;
   proc sort data=PCR_Pos_filtered 
            out= PCR_Person_Date;
      by Person_ID DateAdded;
run;

DATA POS_Person; set PCR_Person_Date;
   by Person_ID DateAdded;
   if first.Person_ID ;
run;
   PROC contents data=POS_Person  varnum ;  title1 'POS_Person';  run;

*** Completeness of DateAdded ***;
   PROC means n nmiss data= POS_Person; var DateAdded; run;


*** Check completeness of address data ***;
***------------------------------------***;

options ps=50 ls=150 ;     * Landscape pagesize settings *;
* Chk1.Address missing *;
   PROC freq data= POS_Person ;
      where Address in ('');
      tables Address * Address2  / list missing missprint;
      format Address Address2   $35.   ;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=3923 obs missing data for Address and Address2
 | N=4 obs where Address='' and Address2 contains data. 
 | FIX:  If Address='' and Address2^='' then Address=Address2;
 *--------------------------------------------------------------------*/


* Chk2.Address invalid *;
   PROC freq data= POS_Person ;
      where notdigit(substr(Address,1))=1;    * selects records where first character is NOT a number *;
      tables Address * Address2  / list missing missprint;
      format Address Address2   $35.   ;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:
 *--------------------------------------------------------------------*/


* Chk3.City missing *;
   PROC freq data= POS_Person ;
      where City = '';
      tables Address * Address2 *  City * State  / list missing missprint;
      format Address  Address2   $35.   City $10. ;
run;
/*----------------------------------------------------------------------------------*
 |FINDINGS:
 | n=1586 obs missing data for Address, City and State
 | n=8 obs missing Address, City
 | n=14 have data in Address but missing City
 *----------------------------------------------------------------------------------*/

* Chk3.1) City missing but have Address data *;
   PROC print data= POS_Person ;
      where City = '' and Address ne '';
      id Person_ID; var Address  Address2   City  State zipcode ;
      format Address  Address2   $35.   City $25. ;
run;


* Chk4.State *;
   PROC freq data= POS_Person ;
      tables State / missing missprint;
run;
/*---------------------------------------------------------------------------------*
 |FINDINGS:
 | Over 98% of records have State=CO
 | n=73 where State = COLORADO
 | n=65 where State = XX
 | Several records have missing State or State = -, ., .., 1C, 81, 99, N/A
 *---------------------------------------------------------------------------------*/

* Chk4.1) Odd State values *;
   PROC print data= POS_Person ;
      where State in ('-', '.', '..', '1C', '81');
      id Person_ID; var Address     City  State zipcode ;
      format Person_ID  Address $30.  Address2 $10.   City $25. ;
run;
   PROC print data= POS_Person ;
      where State in ('99');
      id Person_ID; var Address     City  State zipcode ;
      format Person_ID  Address $30.  Address2 $10.   City $25. ;
run;
   PROC print data= POS_Person ;
      where State in ('N/A');
      id Person_ID; var Address     City  State zipcode ;
      format Person_ID  Address $30.  Address2 $10.   City $25. ;
run;
   PROC print data= POS_Person ;
      where State in ('XX');
      id Person_ID; var Address     City  State zipcode ;
      format Person_ID  Address $30.  Address2 $10.   City $25. ;
run;

* Chk5.County *;
   PROC freq data= POS_Person ;
      where County = '';
      tables County / missing missprint;
run;
/*---------------------------------------------------*
 |FINDINGS:
 | NO obs have missing data for County
 *--------------------------------------------------*/

* Chk6.DOB *;
   PROC freq data= POS_Person ;
      tables  Date_of_Birth / missing missprint;
      format  Date_of_Birth  year.;
run;
/*---------------------------------------------------*
 |FINDINGS:
 | n=109 obs with missing DOB
 | n=13 obs with DOB=1900 and n=6 < 1900
 *--------------------------------------------------*/



*** Records by completeness of components of a complete address ***;
***-------------------------------------------------------------***;

   PROC format;
      value $AnyDataFmt
         ' '='Missing data'
         other='Has data' ;       
run;

 * Colorado Records with full address (address, city, state, county) *;
   PROC freq data= POS_Person  order=freq;
      tables Address * City * State * Zipcode / list missing missprint;
      format Address   City   State   Zipcode $AnyDataFmt.;
run;

/*---------------------------------------------------------------------------*
 |FINDINGS:
 | Almost 99% results have complete data (Address, City, State, Zipcode)
 | All other obs have 5 digit Zipcode
 *---------------------------------------------------------------------------*/



*** Edit data  ***;
***------------***;

DATA POS_Person_temp;  set POS_Person;
* impute missing Address with Address2 or AddressActual *;
   if Address='' and Address2^='' then Address=Address2; 

* clean Address data *;
   Address = compress(Address, "*,.");
   if index(Address, '@')>0 then Address='';

   if index(Address,"ADDRESS")=1 then Address='';
   if index(Address,"AUROR")=1 then Address='';
   if index(Address,"AVE")=1 then Address='';

   if Address in ('BOULDER', 'BROOMFIELD', 'CANON CITY', 'CASTLE ROCK', 'CENTENNIAL', 'COLORADO',
                  'COLORADO SPRINGS', 'CRIPPLE CREEK', 'DENVER', 'DENVER CO', 'DENVER COUNTY JAIL', 'DENVER INTERNATIONAL AIRPORT', 
                  'DENVER RESCUE MISSION', 'DURANGO', 'FOUNTAIN', 'FORT CARSON', 'FT CARSON',
                  'FT COLLINS', 'FURANGO', 'LAKEWOOD', 'PARKER', '', 'STEAMBOAT') then 
      Address='';

   if index(Address,"DO NOT MAIL ANY MEDS")=1 then Address='';
   if index(Address,"DON'T WANT TO DISCLOSE")=1 then Address='';
   if index(Address,"DURANG")=1 then Address='';
   if index(Address,"EL PASO COUNTY JAIL")=1 then Address='';
   if index(Address,"ELIZABETH,")=1 then Address='';
   if index(Address,"FAIRGROUND")=1 then Address='';
   if index(Address,"GENERAL")=1 then Address='';
   if index(Address,"HOME")=1 then Address='';
   if index(Address,"HOTEL")=1 then Address='';
   if index(Address,"INTERSTATE")=1 then Address='';
   if index(Address,"JJJ")=1 then Address='';
   if index(Address,"LAP")=1 then Address='';
   if index(Address,"LARIMER COUNTY")=1 then Address='';
   if index(Address,"LONGMONT")=1 then Address='';
   if index(Address,"NEED")=1 then Address='';
   if index(Address,"NG")=1 then Address='';
   if index(Address,"NNN")=1 then Address='';
   if index(Address,"NO ADDRESS")=1 then Address='';
   if index(Address,"NO REPONSE")=1 then Address='';
   if index(Address,"NO THANK")=1 then Address='';
   if index(Address,"NONE")=1 then Address='';
   if index(Address,"NOT")=1 then Address='';
   if index(Address,"PUEBLO")=1 then Address='';
   if index(Address,"REPL")=1 then Address='';
   if index(Address,"SAME")=1 then Address='';
   if index(Address,"SEE CONFIDENTIAL")=1 then Address='';
   if index(Address,"SEE TEMP")=1 then Address='';
   if index(Address,"THERE IS")=1 then Address='';
   if index(Address,"TRANS")=1 then Address='';
   if index(Address,"UCH")=1 then Address='';
   if index(Address,"UNABLE")=1 then Address='';
   if index(Address,"UPDAT")=1 then Address='';
   if index(Address,"USE OTHER")=1 then Address='';
   if index(Address,"VVV")=1 then Address='';
   if index(Address,"X")=1 then Address='';

   if Address in ('BAD ADDRESS', 'N', 'N/A', 'NA', 'NEED', 'NONE', 'QQ', 'SS', 'ST',
                  'U', 'UN UN', 'UNKOWN', 'UNKS', 'UNKWN', 'UNK', 'UNKNOWN', 'YES'  ) then 
      Address='';

* chk 3.1 *;
   if index(Address,"7375")>0  AND  index(Address,"POTOMAC")>0  then DO; 
      Address='7375 S POTOMAC ST';
      City = 'CENTENNIAL';
      State = 'CO';
      Zipcode = '80112';
   END;
   if Person_ID = 'JENNIFER_ALVEY DZIERZYNSKI_05/15/1970' then DO;
      Address='9071 E MISSISSIPPI AVE';
      CITY = 'DENVER';
      STATE = 'CO';
      ZIPCODE='80247';
   END;
   if Person_ID = 'ROSEMARIE_KUTA_01/20/1961' then DO;
      CITY = 'MONTROSE';
      STATE = 'CO';
      ZIPCODE='81401';
   END;

* chk 4.1 *;
  if State = '1C'  AND  City in ('COLORADO SPRINGS','ASPEN','DURANGO')  THEN State='CO' ;
  if State = '81'  THEN State='CO' ;
  if State = '99'  THEN State='CO' ;
  if State = 'COLORADO'  THEN State='CO' ;

* chk 6 *;
* calculate age at vaccination *;
   if Date_of_Birth > '01JAN1900'd then DO;
      Age_years = INT(Intck('MONTH', Date_of_Birth, DateAdded)/12) ;   
      IF month(Date_of_Birth) = month(DateAdded) then 
         Age_years =  Age_years - ( Day(Date_of_Birth)>Day(DateAdded) );  
   END;


run;


DATA POS_CO_Person ;  set POS_Person_temp ;
      where State='CO';
run;

   PROC contents data=POS_CO_Person  varnum; title1 'POS_CO_Person'; run;


** Number of Colorado records with County, City and Address **;
   PROC freq data= POS_CO_Person order=freq;
      tables Address * City * County / list missing missprint;
      format Address   City   County $AnyDataFmt.;
run;
/*---------------------------------------------------------------------------------*
 |FINDINGS:
 |  N=354,545 filtered PCR positive tests from Colorado with Address, City, and County data
 *---------------------------------------------------------------------------------*/



*** Create Age Groups ***;
***-------------------***;

   PROC freq data= POS_CO_Person;  table Age_years; run;

**  Define Age groups  **;
   PROC format;
      value AgeFmt
         0-<5='Infant'
         5-<12='Kid'
         12-<18='Teen'
         18-115='Adult' 
         other = " " ;
run;

   PROC freq data= POS_CO_Person  ;
      tables Age_years /  missing missprint;
      format Age_years AgeFmt.;
run;
/*----------------------------------------*
 |FINDINGS:
 | n=113 records where Age is missing or invalid.
 | FIX: Filter records out.
 *----------------------------------------*/


*** Define AgeGroup variable                        ***;
*** Filter out records with missing address and age ***;
*** and DROP unnecessary variables                  ***;
***-------------------------------------------------***;
DATA ELR_Addresses;  set POS_CO_Person;
   where (Address ne '')  AND (City ne '')  ;

   AgeGroup = put(Age_years, AgeFmt.);
   AG = put(Age_years, AgeFmt1.);

   DROP  First_Name Last_Name  Address2    AccessionID  ;
run;
   proc freq data=ELR_Addresses ; tables AgeGroup AG; run;
   PROC contents data=ELR_Addresses  varnum; title1 'ELR_Addresses'; run;



*** Count Number cases per HH and restrict to HH with 2+ cases ***;
***------------------------------------------------------------***;

**  Sort filtered cases on address variables to define HH  **;
   proc sort data=ELR_Addresses
               out=ELR_Addresses_sort;
      by County  City  Address  DateAdded ;
run;

** Preview Address1 data **;
   PROC print data= ELR_Addresses_sort(obs=10000);
      ID Person_ID;
      var Address  City   County ;
      format address City $25.   ;
run;
/*------------------------------------------------------------------------------------------*
 |FINDINGS:
 | There are several examples of HH's with slightly different values for Address1
 | Should investigate other addresses that have >10 cases per Address1.
 *--------------------------------------------------------------------------------------------*/



DATA ELR_HouseHolds 
      FlagELRAddress(keep=County  City  Address);  
   set ELR_Addresses_sort;
   by County  City  Address ;

   if first.Address then do;  NumCases_HH=0;  Cluster=1;  NumCases_Cluster=0;  Days_since_last_case=0;  end;
   else Days_since_last_case = DateAdded - lag(DateAdded);

   NumCases_HH+1;

   if Days_since_last_case >30 then do; Cluster+1;  NumCases_Cluster=0;  Days_since_last_case=0;  end;

   NumCases_Cluster+1;
   Days_since_last_case = DateAdded - lag(DateAdded);

   if last.Address then do;
      if NumCases_HH=1 then delete;
      if NumCases_HH>10 then output FlagELRAddress;
   end;

  output ELR_HouseHolds;
run;
/*   proc print data=FlagAddress; run;*/
/*   proc print data= CEDRS_HouseHolds;  id Address1; var NumCases_HH  Address_City Address_State Age_at_Reported ReportedDate ;  run;*/
/*   proc freq data= CEDRS_HouseHolds noprint; tables CountyAssigned * Address_City * Address1/list out=CountCasesperHH; */
/*   proc freq data= CountCasesperHH; tables count; title1 'Number of cases per HH'; run;*/



*** Then remove HH with more than 10 cases ***;
***----------------------------------------***;

Data ELR_HH; merge FlagELRAddress(in=x)  ELR_HouseHolds ;
   by County  City  Address ;
   if x=1 then delete;

   if NumCases_Cluster=1 then Days_between_cases=0;
run;
/*   proc print data= CEDRS_HH;  id ProfileID; var Address1 Address_City Address_State Age_at_Reported ReportedDate ;  run;*/
/*   proc freq data= CEDRS_HH noprint; tables CountyAssigned * Address_City * Address1/list out=CasesperHH; */
/*   proc freq data= CasesperHH; tables count; title1 'Number of cases per HH'; run;*/



*** Transpose data from Case level (tall) to HH level (wide) ***;
***----------------------------------------------------------***;

* transpose ReportedDate *;
   PROC transpose data=ELR_HH  
   out=WideDSN1(drop= _NAME_)
      prefix=DateAdded ; 
      var DateAdded;          
      by County  City  Address  Cluster ;
run;
/*   proc print data= WideDSN1;  run;*/

* transpose AG *;
   PROC transpose data=ELR_HH  
   out=WideDSN2(drop= _NAME_)  
      prefix=AG ; 
      var AG;        
      by County  City  Address  Cluster ;
run;
/*   proc print data= WideDSN2; run;*/

* transpose Days_since_last_case *;
   PROC transpose data=ELR_HH  
   out=WideDSN3(drop= _NAME_)
      prefix=DaysBetween ; 
      var Days_since_last_case;          
      by County  City  Address  Cluster ;
run;
/*   proc print data= WideDSN3;  run;*/



***  Creation of Household (HH) level dataset  ***;
***--------------------------------------------***;

* Merge transposed datasets and final counter together *;
DATA HH_PCR_Pos; merge WideDSN1  WideDSN2  WideDSN3  ;
   by County  City  Address  Cluster ;

   ARRAY RptDates{10} DateAdded1-DateAdded10 ;
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

   PROC contents data=HH_PCR_Pos  varnum; title1 'HH_PCR_Pos'; run;

** To get the number of eligible HH and number of cases in those HH **;
   proc means data= HH_PCR_Pos n sum maxdec=0; var HHcasesTotal; run;
** To get the number of clusters per HH **;
/*   proc freq data= HHcases noprint; tables CountyAssigned * Address_City * Address1  /list out=CountClustersperHH; */
/*   proc freq data= CountClustersperHH; tables count; title1 'Number of clusters per HH'; run;*/



***  Analyze HH level data  ***;
***-------------------------***;

** Number of HH with 1+ case in time period 1, 2, and 1&2. **;
   PROC SQL;
      select count(*) as NumHH22
      from
         (select distinct County, City, Address
      from HH_PCR_Pos where HHcases22>0 );
quit;

   PROC SQL;
      select count(*) as NumHH21
      from
         (select distinct County, City, Address
      from HH_PCR_Pos where HHcases21>0 );
quit;

   PROC SQL;
      select count(*) as NumHH
      from
         (select distinct County, City, Address
      from HH_PCR_Pos );
quit;


** Number of clusters by time period **;
   PROC means data=HH_PCR_Pos n sum maxdec=0;  where HHcases22>0;     var Cluster HHcases22 ;  run;
   PROC means data=HH_PCR_Pos n sum maxdec=0;  where HHcases21>0;     var Cluster HHcases21 ;  run;
   PROC means data=HH_PCR_Pos n sum maxdec=0;  where HHcasesTotal>0;  var Cluster HHcasesTotal ;  run;



** Distribution of FULL list of HH cases involved in time period 1 and 2  **;
   PROC freq data=HH_PCR_Pos ;
      where JAN22_AG ne '';
      tables JAN22_AG    /  missing missprint ;
run;


** Distribution of FIRST CASE per AG's involved in time period 1 and 2  (ALL HH) **;
   PROC freq data=HH_PCR_Pos ;
      where JAN22_AG ne '';
      tables JAN22_AG    /  missing missprint ;
      format JAN22_AG $1.;
run;


   PROC freq data=HH_PCR_Pos ;
      tables AnyKids22 AnyKids21 ;
run;

   PROC freq data=HH_PCR_Pos ;
      where JAN22_AG ne ''  AND  AnyKids22=1;
      tables JAN22_AG    /  missing missprint ;
      format JAN22_AG $1.;
run;


** Average number of cases in clusters by age group of index cases **;
   PROC means data=HH_PCR_Pos mean max  maxdec=2 ;
      where JAN22_AG ne '';
      class JAN22_AG ;
      format JAN22_AG $1.;
      var HHaddcases22;
run;


** Average time between index cases and next case by age group of index case **;
   PROC means data=HH_PCR_Pos mean range  maxdec=2 ;
      where JAN22_AG ne '';
      class JAN22_AG ;
      format JAN22_AG $1.;
      var DaysBetween2;
run;


** Average time between all cases in cluster by age group of index case **;
   PROC means data=HH_PCR_Pos mean range  maxdec=2 ;
      where JAN22_AG ne '';
      class JAN22_AG ;
      format JAN22_AG $1.;
      var MeanTime2Spread;
run;







