PROC EXPORT DATA= WORK.Adams0_115_dates 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\Pediatric case rates\County data\Case_rates_ADAMS.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="data"; 
RUN;
