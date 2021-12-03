PROC IMPORT OUT= WORK.Montrose 
            DATAFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\20
.Montrose VB list\Input data\MontroseClinicList.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="'Patient Details$'"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
