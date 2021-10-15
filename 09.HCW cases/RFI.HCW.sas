/**********************************************************************************************
PROGRAM:  RFI.HCW.sas
AUTHOR:   Eric Bush
CREATED:  September 13, 2021
MODIFIED:	
PURPOSE:	 RFI for chart of hospital admission rates (daily count and 7 d avg) 
INPUT:	 Dr Justina query via Snowflake --> "All Cases with HCW field.XLXS" imported into SAS	  
OUTPUT:		
***********************************************************************************************/
options ps=65 ls=110 ;     * Portrait pagesize settings *;
options ps=50 ls=150 ;     * Landscape pagesize settings *;

**  Access the folder with the final SAS dataset to be used in this code  **;

options pageno=1;

** Use import wizard to read XLXS file **;

** Contents of SOURCE dataset to query for RFI **;
   PROC contents data=hcs_x varnum; 
      title1 'DrJ Snowflake = hcs_x';
run;

** Evaluate Date_Opened field **;
   PROC print data=hcs_x  (obs=50);
      var Date_Opened;
run;

** Describe HCW and Occupation fields **;
   PROC freq data= hcs_x;
      tables HCW  / missing missprint ;
      tables Occupation  / missing missprint ;
run;


** Modify dataset **;
DATA HCW_proportion; set hcs_x;
* Extract year and month from Date_Opened variable *;
   year_opened = scan(Date_Opened,1,'-');
   month_opened = scan(Date_Opened,2,'-');
   Year_Month = cats(year_opened,'_',month_opened);

* Backfill missing HCW data *;
   if HCW='' then DO;
      if index(Occupation, 'healthcare')>0 then HCW='yes';
      else HCW='no';
   END;
run;

** Contents of MODIFIED dataset to respond to RFI **;
   PROC contents data=HCW_proportion varnum; 
      title1 'HCW_proportion';
run;

** Frequency of variables **;
   PROC freq data= HCW_proportion;
      tables HCW;
/*      tables HCW_Type  DIRECT_PATIENT_CARE  Occupation /missing missprint;*/
run;

** Proportion of confirmed cases that were HealthCare workers **;
   PROC freq data= HCW_proportion;
      where Year_Month ^in ('2020_08','2020_09','2021_09');
      tables Year_Month * HCW /nopercent nocol out=HCWprop;
run;




