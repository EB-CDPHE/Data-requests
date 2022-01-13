PROC EXPORT DATA= WORK.ELR_PCR_ANTIGEN 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Dashboard data\EL
Rtests.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;
