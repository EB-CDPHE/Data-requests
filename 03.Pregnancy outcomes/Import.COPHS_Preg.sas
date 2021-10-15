PROC IMPORT OUT= WORK.COPHS_Preg 
            DATAFILE= "J:\Programs\Other Pathogens or Responses\2019-nCo
V\Data\SAS Code\data\Pregnancy_data_062321.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="data$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
