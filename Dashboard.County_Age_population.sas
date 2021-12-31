
*** County Population data ***;
***------------------------***;

TITLE;
OPTIONS pageno=1;

** Create libname with XLSX engine that points to XLSX file **;
libname mysheets xlsx 'C:\Users\eabush\Documents\CDPHE\Requests\data\Pediatric pop by county.xlsx' ;

** see contents of libref - one dataset for each tab of the spreadsheet **;
   PROC contents data=mysheets._all_ ; title1; run;

** print tabs from spreadsheet **;
   proc print data=mysheets.data; run;


Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;
libname DASH 'C:\Users\eabush\Documents\GitHub\Dashboard data' ;  run;

DATA DASH.County_Pediatric_Population; 
   length AgeGroup $ 10 ;
   set mysheets.data;

* Change County FIPS from numeric to character with leading zeros *;
/*   format County z3. ;*/

* Change COUNTY from propcase to UPCASE to join easier in Tableau *;
   County=upcase(COUNTY);

* Change Age group values to match those in Tableau *;
        if Age='0 to 5' then AgeGroup='0-<5'; 
   else if Age='6 to 11' then AgeGroup='5-<12'; 
   else if Age='12 to 17' then AgeGroup='12-<18'; 
   else if Age='18 to 121' then AgeGroup='18-115';

run;


   PROC contents data=DASH.County_Pediatric_Population;  title1 'DASH.County_Pediatric_Population';  run;

   PROC print data= DASH.County_Pediatric_Population; id county; run;



