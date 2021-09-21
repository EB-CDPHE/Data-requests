PROC IMPORT OUT= WORK.JHE 
            DATAFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\CO
 vs national case rates\John Hopkins data\US_cases_JH.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
