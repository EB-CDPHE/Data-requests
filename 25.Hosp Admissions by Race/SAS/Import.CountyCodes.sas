PROC IMPORT OUT= WORK.COUNTYCODES 
            DATAFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\25
.Hosp Admissions by Race\Input data\countycodes.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
