PROC IMPORT OUT= WORK.RacePopData 
            DATAFILE= "C:\Users\eabush\Documents\My Tableau Repository\Datasources\race-estimates-county.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="'race-estimates-county$'"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;



