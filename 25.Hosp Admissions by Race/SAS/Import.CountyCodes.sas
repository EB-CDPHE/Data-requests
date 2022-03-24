PROC IMPORT OUT= WORK.COUNTYCODES 
            DATAFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\25
.Hosp Admissions by Race\Input data\countycodes.xls" 
            DBMS=EXCEL REPLACE;
     RANGE="Sheet1$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
