# Data-requests

## Backgroud: 
### This request is for data needed to complete the table in the MMWR [Notes from the Field](https://docs.google.com/document/d/1Jla02O-FwNHoCOz3zqUEXd80KRmpGzljFKM7hfSf7T4/edit?ts=60f10e65).   
### **Population**:  Confirmed and probable cases with collection dates between April 27 - June 6, 2021 (inclusive).  
### **Outcomes**: case rate per 100k; hospitalization rate; ICU admission rate; case fatality ratio (for all cases and hospitalized cases only).  
### **Groups**: Colorado regions defined as Mesa county versus all other counties ("ROC"). An earlier version of the table asked for outcomes by age (<70 yo and 70+ yo). 
### The earlier version requested data for the same outcomes and groupings but for the population of delta variants isolated from confirmed and probable cases.
#

|     | <p align="left">Steps taken to get data for revised table</p> |
| --- | ------------------------------------------------------------------------------------ |
|1| Run READ.CEDRS_view.sas to acquire data from dphe144 CEDRS_view. Creates CEDRS_view |
|2| Use Check.CEDRS_view for data checks. Output informs edits made in Fix.CEDRS_view|
|3| Run READ.zDSI_Events to get Age. Creates zDSI_Events.read|
|4| Run FIX.zDSI_Events to create Age_in_Years variable|
|5| Run FIX.CEDRS_view to edit data in CEDRS_view and create CEDRS_view_fix
|6| Run RFI.COVID_MMWR.sas to generate numbers for top half of revised table.  
|   | It makes use of the output from these SAS programs that get automatically run:
        1) MMWR.formats.sas
        2) Key_merge.COPHS.CEDRS.sas

#             
## SAS Programs in this folder:

| Program name    | Input Dataset  | Output Dataset   | Purpose                                  
| --------------- | -------------- | ---------------- | ---------------------------------------| 
| READ.CEDRS_view | dbo144.CEDRS_view (SQL data table) | COVID.CEDRS_view | Access CEDRS_view table and adjust variable types and length and save as SAS dataset|
| Check.CEDRS_view| COVID.CEDRS_view|*N/A*|Conduct data quality checks|
|READ.zDSI_Events|dbo66.zDSI_Events|work.zDSI_Events_read|Access Profiles table and adjust variable types and length and save as SAS dataset.
|Fix.zDSI_Events|zDSI_Events_read|zDSI_Events_fix|Convert age for all age types to Age_in_Years
| Fix.CEDRS_view|COVID.CEDRS_view; & zDSI_Events_fix|COVID.CEDRS_view_fix|Edit County and Age variables|
|RFI.DeltaVOC for MMWR|CEDRS_view_fix; & B6172_fix; & County_Population|MMWR_Cases; & MMWR_ICU|Generate numbers for orginal table
|RFI.COVID_MMWR|CEDRS_view_fix|MMWR_Cases; & MMWR_ICU|Generate numbers for revised table
|MMWR_formats| *N/A* | *N/A* |Create user defined formats
|Key_merge.COPHS.CEDRS|dbo66.Profiles; & COVID.COPHS_fix; & MMWR_cases|MMWR_ICU|Merge ICU data from COPHS into MMWR_Cases
||
|**RETIRED PROGRAMS:** | |
| Read.B6172|SQL tables from CEDRS66 zDSI schema: <ul><li>Profiles</li><li>Events</li></ul><ul><li>LabTests</li></ul> |B6172_read|Create SAS dataset of variant cases|
| Read.B6172|SQL tables (Profiles, Events, LabTests) from CEDRS66 zDSI schema |B6172_read|Create SAS dataset of variant cases|| READ.populations|dbo144.populations|COVID.County_Population|Create SAS dataset of county population data|
|Check.B6172|B6172_read OR B6172_fix|*N/A*|Conduct data quality checks|
|Fix.B6172|B6172_read|COVID.B6172_fix|Make edits to B6172.read dataset
| READ.COPHS| Hosp144.COPHS|COVID.COPHS|Create SAS dataset from COPHS hospital data|
| READ.populations|dbo144.populations|COVID.County_Population|County population data to merge with ...|

