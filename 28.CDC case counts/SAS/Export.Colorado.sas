PROC EXPORT DATA= WORK.BULK_HISTORICAL_032222_COLORADO 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\28.CDC case counts\Output\Bulk_Historical_Update_Colorado_2022-03-22.xlsx" 
            DBMS=EXCEL LABEL REPLACE;
     SHEET="Jurisdictional Aggregate Data"; 
RUN;
