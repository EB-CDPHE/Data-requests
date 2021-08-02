/*
PROGRAM:  Excel.import.sas 
PURPOSE:  Read data from excel spreadsheet 
*/

** Check that have SAS version of 9.4 M2 or greater **;
%put my version of sas is &sysvlong;

** Create libname with XLSX engine that points to XLSX file **;
libname mysheets xlsx 'C:\Users\eabush\Documents\CDPHE\Requests\data\Lost_Valley.xlsx' ;

** see contents of libref - one dataset for each tab of the spreadsheet **;
proc contents data=mysheets._all_ ; run;

** print tabs from spreadsheet **;
proc print data=mysheets.cabins; run;
proc print data=mysheets.horses; run;

