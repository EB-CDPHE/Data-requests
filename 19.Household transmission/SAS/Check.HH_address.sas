/**********************************************************************************************
PROGRAM:  Check.HH_address.sas
AUTHOR:   Eric Bush
CREATED:  December 8, 2021
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



*** Filter data  ***;
***--------------***;

DATA CEDRS_filtered;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND
   (  ('01SEP20'd le  ReportedDate  le '01NOV20'd ) OR ('01SEP21'd le  ReportedDate  le '01NOV21'd)  ) 
      AND LiveInInstitution ne 'Yes';

   Keep  ProfileID EventID  CountyAssigned   ReportedDate   Age_at_Reported   CollectionDate   
         LiveInInstitution   Homeless   Outbreak_Associated   Symptomatic  OnsetDate 
         Address:  ;
run;

   PROC contents data=CEDRS_filtered  varnum ;  title1 'CEDRS_filtered';  run;



*** Zipcode values ***;
***----------------***;

   PROC freq data= CEDRS_filtered ;
      tables Address_Zipcode / missing missprint;
run;
/*-------------------------------------------------------------------------*
 |FINDINGS:
 | For zipcode with 9 digits need to insert '-'.
 | Then need to create numeric zipcode from first 'word' 
 | Then can use zipcode range (80000 - 81700) to fill in missing State
 *-------------------------------------------------------------------------*/


options ps=50 ls=150 ;     * Landscape pagesize settings *;

** Chk1:  Zip code with commas **;
   PROC print data= CEDRS_filtered;
      where index(Address_Zipcode,',')>0;
      id ProfileID EventID;
      var Address1 Address2 AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $10. ;
run;
/*-----------------------------------------------------------------------------------------------*
 |FIX:
  if ProfileID in ("1224468.1","1824521") then Address_Zipcode=compress(Address_Zipcode, ',');
 *-----------------------------------------------------------------------------------------------*/


** Chk2:  Zip code with length=4 **;
   PROC print data= CEDRS_filtered;
      where length( compress(Address_Zipcode) )=4;
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*-----------------------------------------------------------------*
 |FIX:

   if ProfileID in ('1787033') then Address_Zipcode = '80234';
   if ProfileID in ('1809231') then Address_Zipcode = '80735';
   if ProfileID in ('1813537') then Address_Zipcode = '81069';
   if ProfileID in ('1820354') then Address_Zipcode = '80602';
   if ProfileID in ('1832458') then Address_Zipcode = '81321';
   if ProfileID in ('1832472') then Address_Zipcode = '81321';
   if ProfileID in ('1838966') then Address_Zipcode = '80439';
   if ProfileID in ('1845873') then Address_Zipcode = '80915';
   if ProfileID in ('1845873') then DO; 
      Address1 = '640 NORTH MURRAY BLVD';
      Address2 = 'APT 227';
      Address_City = 'COLORADO SPRINGS';
   END;
   if ProfileID in ('1848984') then Address_Zipcode = '81007';
   if ProfileID in ('1848984') then DO;
      Address1 = '435 W LITTLER DR';
   END;
   if ProfileID in ('1850506') then Address_Zipcode = '80205';
   if ProfileID in ('1867510') then Address_Zipcode = '81523';
   if ProfileID in ('1890581') then Address_Zipcode = '80911';
   if ProfileID in ('1890581') then DO;
      Address1 = '117 KOKOMO ST.';
      Address2 = 'APT. D';
   END;
   if ProfileID in ('1892377') then Address_Zipcode = '80538';
   if ProfileID in ('1910791') then Address_Zipcode = '80214';

   if ProfileID in ('1917019') then Address_Zipcode = '81001';
   if ProfileID in ('1917768') then Address_Zipcode = '80127';
   if ProfileID in ('1918088') then Address_Zipcode = '80123';
   if ProfileID in ('1922636') then Address_Zipcode = '80601';
   if ProfileID in ('1942000') then Address_Zipcode = '80214';
   if ProfileID in ('1136170') then Address_Zipcode = '80016';
   if ProfileID in ('1138005') then Address_Zipcode = '81641';
   if ProfileID in ('1165757') then Address_Zipcode = '80526';
   if ProfileID in ('1165757') then DO; 
      Address1 = '4500 SENECA ST';
      Address_City = FORT COLLINS';
   END;
   if ProfileID in ('1178217') then Address_Zipcode = '80002';
   if ProfileID in ('1190606') then Address_Zipcode = '80904';
   if ProfileID in ('1200802') then Address_Zipcode = '80109';

   if ProfileID in ('1824521') then Address_Zipcode = '80631';
   if ProfileID in ('1824521') then DO;
      Address1 = '1705 28TH ST';
   END;

 *------------------------------------------------------------------*/


** Chk3:  Zip code < 00004 **;
   PROC print data= CEDRS_filtered;
      where Address_Zipcode in ('00000','00001','00003');
      id ProfileID ;
      var Address1     Address_City      Address_State  Address_Zipcode  CountyAssigned  ;
      format Address1  AddressActual  $20.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*-----------------------------------------------------------------*
 |FIX:
 | Most of these have address1 = "GENERAL DELIVERY".  
 | Should zip be set to missing for these?

   if ProfileID in ('1725872.1') then Address_Zipcode = '80113';
   if ProfileID in ('1911167') then Address_Zipcode = '81022';
 *-----------------------------------------------------------------*/


** Chk4:  Zip code with length=6 **;
   PROC print data= CEDRS_filtered;
      where length(Address_Zipcode)=6;
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State  Address_Zipcode  CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*----------------------------------------------------------------------*
 |FIX:

   if ProfileID in ('1798946') then Address_Zipcode = '80921';
   if ProfileID in ('1827041') then Address_Zipcode = '';
   if ProfileID in ('1062180.1') then Address_Zipcode=compress(Address_Zipcode);
   if ProfileID in ('1139630') then Address_Zipcode=compress(Address_Zipcode);
   if ProfileID in ('1161466') then Address_Zipcode = '80021';
   if ProfileID in ('1163657') then Address_Zipcode = '80004';
   if ProfileID in ('1167024') then Address_Zipcode=compress(Address_Zipcode);
   if ProfileID in ('1168983') then Address_Zipcode = '80920';
   if ProfileID in ('1175089') then Address_Zipcode = '80238';
   if ProfileID in ('1188080') then Address_Zipcode = '81101';
   if ProfileID in ('1190997') then Address_Zipcode = '81435';
   if ProfileID in ('1190997') then DO;
      Address1 = '280 S MAHONEY DR';
   END;
   if ProfileID in ('1199577') then Address_Zipcode=compress(Address_Zipcode,'`');

 *-----------------------------------------------------------------------*/


** Chk5:  Zip code with length=9 **;
   PROC print data= CEDRS_filtered;
      where length(Address_Zipcode)=9;
      var  Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $10. ;
run;
/*--------------------------------------------------------------------------------------------*
 |FIX:
   if length(Address_Zipcode)=9 then 
   Address_Zip4 = cat( substr(Address_Zipcode, 1, 5), '-', substr(Address_Zipcode, 6) );
 *--------------------------------------------------------------------------------------------*/


** Chk6:  Values that are Zip code - plus four **;
   PROC print data= CEDRS_filtered;
      where index(Address_Zipcode,'-')=6;
      var  Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $10. ;
run;
/*--------------------------------------------------------------------------------------------*
 |FIX:
   if ProfileID in ('1183106') then Address_Zipcode = '80221';
   if index(Address_Zipcode,'-')=6 then Address_Zip4 = Address_Zipcode;
 *--------------------------------------------------------------------------------------------*/


** Chk7:  Zip code with length=3 **;
   PROC print data= CEDRS_filtered;
      where length( compress(Address_Zipcode) )=3;
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*---------------------------------------------------------------*
 |FIX:
   if ProfileID in ('1793141') then Address_Zipcode = '80235';
   if ProfileID in ('1192621') then Address_Zipcode = '80232';
 *---------------------------------------------------------------*/


** Chk8:  Zip code with alpha  **;
   PROC print data= CEDRS_filtered;
      where ANYalpha(Address_Zipcode)>0;
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*---------------------------------------------------------------*
 |FIX:

   if ProfileID in ('1782423') then Address_Zipcode = '';
   if ProfileID in ('1837939') then Address_Zipcode = '';
   if ProfileID in ('1839281') then Address_Zipcode = '80504';
   if ProfileID in ('1849305') then Address_Zipcode = '';
   if ProfileID in ('1853950') then Address_Zipcode = '80631';
   if ProfileID in ('1862614') then Address_Zipcode = '81212';
   if ProfileID in ('1919849') then Address_Zipcode = '';
   if ProfileID in ('1159268') then Address_Zipcode = '80233';
   if ProfileID in ('1192621') then Address_Zipcode = '80232';
   if ProfileID in ('1196519') then Address_Zipcode = '80640';
   if ProfileID in ('1196519') then DO;
      Address1 = '6500 E. 88TH AVE';
      Address2 = 'SP. 244';
   END;

 *---------------------------------------------------------------*/


** Chk9:  Zip code with length=8 **;
   PROC print data= CEDRS_filtered;
      where length( compress(Address_Zipcode) )=8;
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*---------------------------------------------------------------*
 |FIX:
   if ProfileID in ('1138713') then Address_Zipcode = '80210';
 *---------------------------------------------------------------*/


** Chk10:  Zip code with length=7 **;
   PROC print data= CEDRS_filtered;
      where length( compress(Address_Zipcode) )=7;
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*---------------------------------------------------------------------*
 |FIX:
   if ProfileID in ('1835031') then Address_Zipcode = '80908-7420';
   if ProfileID in ('1882941') then Address_Zipcode = '80911-1675';
 *----------------------------------------------------------------------*/


** Chk11:  Zip code = 99999 **;
   PROC print data= CEDRS_filtered;
      where  compress(Address_Zipcode) = '99999' ;
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*------------------------------------------------------*
 |FIX:

   if ProfileID in ('1788953') then Address_Zipcode = '80751';
   if ProfileID in ('1845892') then Address_Zipcode = '80206';
   if ProfileID in ('1860954') then Address_Zipcode = '80231';
   if ProfileID in ('1991145') then Address_Zipcode = '80138';
   if ProfileID in ('1171752') then Address_Zipcode = '80247';
   if ProfileID in ('1176504') then Address_Zipcode = '80122';

 *------------------------------------------------------*/



*** Apply edits to bad ZipCode data ***;
***---------------------------------***;

DATA CEDRS_ZipFix ; set CEDRS_filtered ;

* Chk1 *;
  if ProfileID in ("1224468.1","1824521") then Address_Zipcode=compress(Address_Zipcode, ',');

* Chk2 *;
   if ProfileID in ('1787033') then Address_Zipcode = '80234';
   if ProfileID in ('1809231') then Address_Zipcode = '80735';
   if ProfileID in ('1813537') then Address_Zipcode = '81069';
   if ProfileID in ('1820354') then Address_Zipcode = '80602';
   if ProfileID in ('1832458') then Address_Zipcode = '81321';
   if ProfileID in ('1832472') then Address_Zipcode = '81321';
   if ProfileID in ('1838966') then Address_Zipcode = '80439';
   if ProfileID in ('1845873') then Address_Zipcode = '80915';
   if ProfileID in ('1845873') then DO; 
      Address1 = '640 NORTH MURRAY BLVD';
      Address2 = 'APT 227';
      Address_City = 'COLORADO SPRINGS';
   END;
   if ProfileID in ('1848984') then Address_Zipcode = '81007';
   if ProfileID in ('1848984') then DO;
      Address1 = '435 W LITTLER DR';
   END;
   if ProfileID in ('1850506') then Address_Zipcode = '80205';
   if ProfileID in ('1867510') then Address_Zipcode = '81523';
   if ProfileID in ('1890581') then Address_Zipcode = '80911';
   if ProfileID in ('1890581') then DO;
      Address1 = '117 KOKOMO ST.';
      Address2 = 'APT. D';
   END;
   if ProfileID in ('1892377') then Address_Zipcode = '80538';
   if ProfileID in ('1910791') then Address_Zipcode = '80214';

   if ProfileID in ('1917019') then Address_Zipcode = '81001';
   if ProfileID in ('1917768') then Address_Zipcode = '80127';
   if ProfileID in ('1918088') then Address_Zipcode = '80123';
   if ProfileID in ('1922636') then Address_Zipcode = '80601';
   if ProfileID in ('1942000') then Address_Zipcode = '80214';
   if ProfileID in ('1136170') then Address_Zipcode = '80016';
   if ProfileID in ('1138005') then Address_Zipcode = '81641';
   if ProfileID in ('1165757') then Address_Zipcode = '80526';
   if ProfileID in ('1165757') then DO; 
      Address1 = '4500 SENECA ST';
      Address_City = 'FORT COLLINS';
   END;
   if ProfileID in ('1178217') then Address_Zipcode = '80002';
   if ProfileID in ('1190606') then Address_Zipcode = '80904';
   if ProfileID in ('1200802') then Address_Zipcode = '80109';

   if ProfileID in ('1824521') then Address_Zipcode = '80631';
   if ProfileID in ('1824521') then DO;
      Address1 = '1705 28TH ST';
   END;

* Chk3 *;
   if ProfileID in ('1725872.1') then Address_Zipcode = '80113';
   if ProfileID in ('1911167') then Address_Zipcode = '81022';

* Chk4 *;
   if ProfileID in ('1798946') then Address_Zipcode = '80921';
   if ProfileID in ('1827041') then Address_Zipcode = '';
   if ProfileID in ('1062180.1') then Address_Zipcode=compress(Address_Zipcode);
   if ProfileID in ('1139630') then Address_Zipcode=compress(Address_Zipcode);
   if ProfileID in ('1161466') then Address_Zipcode = '80021';
   if ProfileID in ('1163657') then Address_Zipcode = '80004';
   if ProfileID in ('1167024') then Address_Zipcode=compress(Address_Zipcode);
   if ProfileID in ('1168983') then Address_Zipcode = '80920';
   if ProfileID in ('1175089') then Address_Zipcode = '80238';
   if ProfileID in ('1188080') then Address_Zipcode = '81101';
   if ProfileID in ('1190997') then Address_Zipcode = '81435';
   if ProfileID in ('1190997') then DO;
      Address1 = '280 S MAHONEY DR';
   END;
   if ProfileID in ('1199577') then Address_Zipcode=compress(Address_Zipcode,'`');

* Chk5 *;
   if length(Address_Zipcode)=9 then do;
      Address_Zip4 = cat( substr(Address_Zipcode, 1, 5), '-', substr(Address_Zipcode, 6) );
      Address_Zipcode = substr(Address_Zipcode, 1, 5);
   end;

* Chk6 *;
   if ProfileID in ('1183106') then Address_Zipcode = '80221';
   if index(Address_Zipcode,'-')=6 then do;
      Address_Zip4 = Address_Zipcode;
      Address_Zipcode = scan(Address_Zipcode,1,'-');
   end;

* Chk7 *;
   if ProfileID in ('1793141') then Address_Zipcode = '80235';
   if ProfileID in ('1192621') then Address_Zipcode = '80232';

* Chk8 *;
   if ProfileID in ('1782423') then Address_Zipcode = '';
   if ProfileID in ('1837939') then Address_Zipcode = '';
   if ProfileID in ('1839281') then Address_Zipcode = '80504';
   if ProfileID in ('1849305') then Address_Zipcode = '';
   if ProfileID in ('1853950') then Address_Zipcode = '80631';
   if ProfileID in ('1862614') then Address_Zipcode = '81212';
   if ProfileID in ('1919849') then Address_Zipcode = '';
   if ProfileID in ('1159268') then Address_Zipcode = '80233';
   if ProfileID in ('1192621') then Address_Zipcode = '80232';
   if ProfileID in ('1196519') then Address_Zipcode = '80640';
   if ProfileID in ('1196519') then DO;
      Address1 = '6500 E. 88TH AVE';
      Address2 = 'SP. 244';
   END;

* Chk9 *;
   if ProfileID in ('1138713') then Address_Zipcode = '80210';

* Chk10 *;
   if ProfileID in ('1835031') then do;
      Address_Zip4 = '80908-7420';
      Address_Zipcode = scan(Address_Zip4,1,'-');
   end;
   if ProfileID in ('1882941') then do;
      Address_Zip4 = '80911-1675';
      Address_Zipcode = scan(Address_Zip4,1,'-');
   end;

* Chk11 *;
   if ProfileID in ('1788953') then Address_Zipcode = '80751';
   if ProfileID in ('1845892') then Address_Zipcode = '80206';
   if ProfileID in ('1860954') then Address_Zipcode = '80231';
   if ProfileID in ('1991145') then Address_Zipcode = '80138';
   if ProfileID in ('1171752') then Address_Zipcode = '80247';
   if ProfileID in ('1176504') then Address_Zipcode = '80122';

run;

   PROC contents data=CEDRS_ZipFix  varnum ;  title1 'CEDRS_ZipFix';  run;

*** new fixed Zipcode values ***;
***--------------------------***;

   PROC freq data= CEDRS_ZipFix ;
      tables Address_Zipcode * Address_Zip4 / list missing missprint;
run;



***  State values  ***;
***----------------***;

   PROC freq data= CEDRS_ZipFix ;
      tables Address_State / missing missprint;
run;
/*----------------------------------------------*
 |FINDINGS:
 | Over 98% of records have State=CO
 | N=2997 records where State = missing
 *----------------------------------------------*/

** Chk12:  Missing State value **;

   PROC format;
      value $AnyDataFmt
         ' '='Missing data'
         other='Has data' ;     
      value $COzip
         '80000' - '81800' = 'CO zip'
         other = 'Non-CO zip' ; 
run;

   PROC freq data= CEDRS_filtered ;
      where Address_State='';
      tables Address1 * Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1  Address_City  Address_State Address_Zipcode  $AnyDataFmt.  ;
run;
/*------------------------------------------------*
 |FINDINGS:
 | Of the N=2997 records where State = missing,
 | n=2700 have address1, city, and Zipcode data
 *------------------------------------------------*/

   PROC freq data= CEDRS_filtered ;
      where Address_State=''  AND  Address_Zipcode ne ''  AND Address1 ne '' AND Address_City ne '';
      tables Address1 * Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1  Address_City  Address_State  $AnyDataFmt.  Address_Zipcode $COzip. ;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:
 | Of the n=2700 records where State = missing,
 | AND there is address1, city, and Zipcode data,
 | ALL but 3 have a CO zip code.
 |FIX:
   if Address_State=''  AND  Address1 ne '' AND Address_City ne '' 
      AND  ( Address_Zipcode>'8000' AND  Address_Zipcode<'81800' )
      then Address_State='CO ZIP'
 *---------------------------------------------------------------------*/


*** Impute State=CO for Zip in (80000 - 81700) ***;
***--------------------------------------------***;

DATA CEDRS_ZipStateFix ; set CEDRS_ZipFix ;

* Chk12 *;
   if Address_State=''  AND  Address1 ne '' AND Address_City ne '' AND 
      ( Address_Zipcode GE '80000' AND  Address_Zipcode LE '81700' )
      then Address_State='CO ZIP' ;
run;

** Contents of dataset with fixzed Zipcode and State **;
   PROC contents data=CEDRS_ZipStateFix  varnum ;  title1 'CEDRS_ZipStateFix';  run;

*** new State distribution with fixed Zipcode ***;
***-------------------------------------------***;

   PROC freq data= CEDRS_ZipStateFix ;
      tables Address_State * Address_Zipcode/ list missing missprint;
run;


***  Missing City for State=CO  ***;
***-----------------------------***;


** Chk13: Missing City **;
   PROC freq data= CEDRS_ZipStateFix ;
      where  Address_State='CO'  AND  Address_City = ''  ;
      tables Address1 * Address_City * Address_State * Address_Zipcode / list missing missprint;
      format Address1  Address_City  Address_State Address_Zipcode  $AnyDataFmt.  ;
run;
/*------------------------------------------------------------*
 |FINDINGS:
 | N=189 records where City = missing,
 | n=134 are also missing address1, State, and Zipcode data.
 | FIX:  Leave as city as missing.
 |
 | n=42 records have address1, State, and Zipcode.
 |FIX:  Google address and find City.
 *------------------------------------------------------------*/

   PROC print data= CEDRS_ZipStateFix;
      where  Address_State='CO'  AND  Address_City = ''  AND Address1 ^= ''  AND Address_Zipcode ^= '' ;
      id ProfileID ;
      var Address1 Address2 Address_Zipcode  Address_City      Address_State    ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_State  $10. ;
run;

/*---------------------------------------------------------------------*
 |FIX:

   if ProfileID in ('1790803') then Address_City = 'GRAND JUNCTION';
   if ProfileID in ('1805723') then Address_City = 'CANON CITY';
   if ProfileID in ('1810320') then Address_City = 'DENVER';
   if ProfileID in ('997479') then Address_City = 'CANON CITY';
   if ProfileID in ('1829366') then Address_City = 'PUEBLO';
   if ProfileID in ('1829683') then Address_City = 'ELIZABETH';
   if ProfileID in ('1839692') then Address_City = 'ENGLEWOOD';
   if ProfileID in ('1841660') then Address_City = 'CANON CITY';
   if ProfileID in ('1843376') then Address_City = 'CANON CITY';
   if ProfileID in ('1859049') then Address_City = 'CANON CITY';
   if ProfileID in ('1879416') then Address_City = 'ALAMOSA';
   if ProfileID in ('1859049') then Address_City = 'CANON CITY';
   if ProfileID in ('1893018') then DO;
      Address_City = Address2;   Address2='';
   END;
   if ProfileID in ('1893019') then DO;
      Address_City = Address2;   Address2='';
   END;
   if ProfileID in ('1900125') then Address_City = 'CANON CITY';
   if ProfileID in ('1915665') then Address_City = 'DENVER';
   if ProfileID in ('1915738') then Address_City = 'ARVADA';
   if ProfileID in ('1915745') then DO;
      Address_City = 'DENVER';
      Address1 = '2636 KENDALL ST';
      Address2 = 'Apt. 302';
   END;
   if ProfileID in ('1915747') then DO;
      Address_City = 'DENVER';
      Address1 = '1540 S ALBION ST';
      Address2 = '#104';
   END;
   if ProfileID in ('1915750') then Address_City = 'LITTLETON';
   if ProfileID in ('1915751') then DO;
      Address_City = 'ARVADA';
      Address1 = '5378 ALLISON ST';
      Address2 = '#103';
   END;
   if ProfileID in ('1915876') then Address_City = 'PUEBLO WEST';
   if ProfileID in ('1915877') then DO;
      Address_City = 'DENVER';
      Address1 = '1490 ZENOBIA ST';
      Address2 = '#203';
   END;
   if ProfileID in ('1915878') then DO;
      Address_City = 'FORT COLLINS';
      Address1 = '3717 S TAFT HILL RD';
      Address2 = 'LOT 68';
      Address_Zipcode = '80526';
   END;
   if ProfileID in ('1915884') then Address_City = 'ARVADA';
   if ProfileID in ('1915885') then Address_City = 'DENVER';
   if ProfileID in ('1915886') then Address_City = 'WHEAT RIDGE';
   if ProfileID in ('1915919') then Address_City = 'DENVER';
   if ProfileID in ('1915920') then DO;
      Address_City = 'LAKEWOOD';
      Address1 = '5995 W HAMPDEN AVE';
      Address2 = 'B9';
   END;
   if ProfileID in ('1915922') then Address_City = 'GREELEY';
   if ProfileID in ('1915923') then DO;
      Address_City = 'LITTLETON';
      Address1 = '8457 S REED ST';
      Address2 = '102';
   END;
   if ProfileID in ('1916402') then Address_City = 'ALAMOSA';
   if ProfileID in ('1916558') then DO;
      Address_City = 'LAKEWOOD';
      Address1 = '7856 W MANSFIELD PKWY';
      Address2 = '#7106';
   END;
   if ProfileID in ('926063') then Address_City = 'LITTLETON';
   if ProfileID in ('1921062') then Address_City = 'PUEBLO';
   if ProfileID in ('1158858') then Address_City = 'DENVER';


 *----------------------------------------------------------------------*/










   PROC freq data= CEDRS_ZipStateFix ;
      tables  Address_City * Address_State  / list missing missprint;
run;
