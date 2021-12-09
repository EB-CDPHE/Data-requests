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
***------------***;

DATA CEDRS_filtered;  set COVID.CEDRS_view_fix;
   if CountyAssigned ^= 'INTERNATIONAL'  AND
   (  ('01SEP20'd le  ReportedDate  le '01NOV20'd ) OR ('01SEP21'd le  ReportedDate  le '01NOV21'd)  ) 
      AND LiveInInstitution ne 'Yes';

   Keep  ProfileID EventID  CountyAssigned   ReportedDate   Age_at_Reported   CollectionDate   
         LiveInInstitution   Homeless   Outbreak_Associated   Symptomatic  OnsetDate 
         Address:  ;
run;

   PROC contents data=CEDRS_filtered  varnum ;  title1 'CEDRS_filtered';  run;



* Zipcode values *;
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
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State  Address_Zipcode  CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
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


** Chk10:  Zip code with length=8 **;
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


** Chk11:  Zip code with length=8 **;
   PROC print data= CEDRS_filtered;
/*      where  compress(Address_Zipcode) = '80908-7420' ;*/
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
/*------------------------------------------------------*
 |FIX:
   if ProfileID in ('') then Address_Zipcode = '';
 *------------------------------------------------------*/




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
      Address_Zipcode = scan(Address_Zipcode,1,'-');
   end;
   if ProfileID in ('1882941') then do;
      Address_Zip4 = '80911-1675';
      Address_Zipcode = scan(Address_Zipcode,1,'-');
   end;

run;


* Zipcode values *;
   PROC freq data= CEDRS_ZipFix ;
      tables Address_Zipcode * Address_Zip4 / list missing missprint;
run;



** Chk2:  Zip code with length=4 **;
   PROC print data= CEDRS_ZipFix;
      where length( compress(Address_Zipcode) )=4;
      id ProfileID ;
      var Address1 Address2  AddressActual  Address_City  Address_CityActual    Address_State Address_Zipcode CountyAssigned  ;
      format Address1  AddressActual  $35.  Address2  Address_City  Address_CityActual  $15. ;
run;
