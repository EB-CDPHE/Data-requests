PROC EXPORT DATA= DEVON.Lat_long_missing 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Dashboard data\Mi
ssing_Lat_Long.XLS" 
            DBMS=EXCEL REPLACE;
     SHEET="CO_Addresses"; 
RUN;
