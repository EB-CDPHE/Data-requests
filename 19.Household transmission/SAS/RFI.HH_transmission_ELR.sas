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
* Chk1.Address1 missing *;
   PROC freq data= POS_Person ;
      where Address in ('');
      tables Address * Address2  / list missing missprint;
      format Address Address2   $35.   ;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:
 | n=3923 obs missing data for Address and Address2
 | N=4 obs where Address1='' and Address2 contains data. 
 | FIX:  If Address='' and Address2^='' then Address=Address2;
 *--------------------------------------------------------------------*/


* Chk2.Address1 invalid *;
   PROC freq data= POS_Person ;
      where notdigit(substr(Address,1))=1;    * selects records where first character is NOT a number *;
      tables Address * Address2  / list missing missprint;
      format Address Address2   $35.   ;
run;
/*--------------------------------------------------------------------*
 |FINDINGS:



 | n>1 obs where Address begins with punctuation e.g. ', *, ,
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



*** Edit data  ***;
***------------***;

DATA POS_CO_Person;  set POS_CO_Person_temp;
      where Address_State='CO';

* impute missing Address1 with Address2 or AddressActual *;
   if Address='' and Address2^='' then Address1=Address2; 

* clean Address1 data *;
   Address = compress(Address, *,.);
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
   if index(Address1,"NO ADDRESS")=1 then Address1='';
   if index(Address1,"NO REPONSE")=1 then Address1='';
   if index(Address1,"NO THANK")=1 then Address1='';
   if index(Address,"NONE")=1 then Address='';
   if index(Address1,"NOT")=1 then Address1='';
   if index(Address1,"PUEBLO")=1 then Address1='';
   if index(Address1,"REPL")=1 then Address1='';
   if index(Address1,"SAME")=1 then Address1='';
   if index(Address,"SEE CONFIDENTIAL")=1 then Address='';
   if index(Address,"SEE TEMP")=1 then Address='';



   if Address in ('BAD ADDRESS', 'N', 'N/A', 'NA', 'NEED', 'NONE', 
                  'U', 'UKNOWN', 'UNDOMICILED', 'UNK', 'UNKNOWN'  ) then 
      Address='';





DATA POS_CO_Person;  set POS_Person;
      where Address_State='CO';

* impute missing collectiondates *;
   if CollectionDate = . then CollectionDate = ReportedDate;

* clean up Address1 data *;
   if Address1='' and Address2^='' then Address1=Address2; 
   else if Address1='' and AddressActual^='' then Address1=AddressActual;

