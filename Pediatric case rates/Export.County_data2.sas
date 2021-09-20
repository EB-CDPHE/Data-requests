PROC EXPORT DATA= WORK.All_county_combine 
            OUTFILE= "C:\Users\eabush\Documents\GitHub\Data-requests\Ped
iatric case rates\County data\All_County_combine.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="data"; 
     NEWFILE=YES;
RUN;
