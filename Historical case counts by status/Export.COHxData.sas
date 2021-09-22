PROC EXPORT DATA= WORK.Cases_stats 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\His
torical case counts by status\Colorado_Historical_data.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;
