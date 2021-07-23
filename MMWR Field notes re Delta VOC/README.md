# Data-request for MMWR Notes from the Field article

## Background: 
This request is for data needed to complete the table in the MMWR [Notes from the Field](https://docs.google.com/document/d/1Jla02O-FwNHoCOz3zqUEXd80KRmpGzljFKM7hfSf7T4/edit?ts=60f10e65).  **Population**:  Confirmed and probable cases with collection dates between April 27 - June 6, 2021 (inclusive).  **Outcomes**: case rate per 100k; hospitalization rate; ICU admission rate; case fatality ratio (for all cases and hospitalized cases only).  **Groups**: Colorado regions defined as Mesa county versus all other counties ("ROC"). An earlier version of the table asked for outcomes by age (<70 yo and 70+ yo).  

First request: Same outcomes. Grouping was for <70 yo vs 70+ yo by region (Mesa vs ROC). The population was all cases (confirmed and probable) and also the population of delta variants.
Second request: Same outcomes. No grouping by age and dropped the population of delta variants.
Third request: Same outcomes. Add grouping by age (5 categories). Only vonfirmed and probable COVID cases, does not look specifically at delta variants.
#

|     | <p align="left">Steps taken to get data for revised table</p> |
| --- | ------------------------------------------------------------------------------------ |
|1| Run Access.CEDRS_view to acquire data from dphe144 CEDRS_view. Creates CEDRS_view_read  |
|2| Use Check.CEDRS_view for data checks. Output informs edits made in Fix.CEDRS_view|
|3| Run Access.zDSI_Events to get Age. Creates zDSI_Events.read|
|4| Run FIX.zDSI_Events to create Age_in_Years variable|
|5| Run FIX.CEDRS_view to edit data in CEDRS_view_read, add Age_in_Years variable.  Creates CEDRS_view_fix
|6| Run Access.B6172.sas to acquire variant data from dphe66 tables. Creates B6172_read |
|7| Use Check.B6172 for data checks. Output informs edits made in Fix.B6172|
|8| Run FIX.B6172 to edit data in B6172_read.  Creates B6172_fix
|9| Run Access.COPHS to acquire data from hosp144 COPHS. Creates COPHS_read  |
|10| Use Check.COPHS for data checks. Output informs edits made in Fix.COPHS|
|11| Run FIX.COPHS to edit data in COPHS_read.  Creates COPHS_fix
|12| Run RFI.MMWR_NFTF_Table3.sas to generate numbers for results table.  
|   | It makes use of the output from these SAS programs that get automatically run:
        1) MMWR.formats to create user-defined formats to recategorize data
        2) Key_merge.COPHS.CEDRS to merge COPHS data with CEDRS data

#             
## SAS Programs in this folder:

| Program name    | Input Dataset  | Output Dataset   | Purpose                                  
| --------------- | -------------- | ---------------- | ---------------------------------------| 
|RFI.MMWR_NFTF_Table1|CEDRS_view_fix; B6172_fix; COPHS_fix|MMWR_Cases & MMWR_ICU|Generate numbers for **first** data request table
|RFI.MMWR_NFTF_Table2|CEDRS_view_fix; B6172_fix; COPHS_fix|MMWR_Cases & MMWR_ICU|Generate numbers for **second** data request table
|RFI.MMWR_NFTF_Table3|CEDRS_view_fix; B6172_fix; COPHS_fix|MMWR_Cases & MMWR_ICU|Generate numbers for **third** data request table
|MMWR_formats| *N/A* | *N/A* |Create user defined formats
|Key_merge.COPHS.CEDRS|dbo66.Profiles; & COVID.COPHS_fix; & MMWR_cases|MMWR_ICU|Merge ICU data from COPHS into MMWR_Cases
|Delta_Story.sas| COVID.CEDRS_view; COVID.B6172_fix; COVID.County_Population | MMWR_cases | free lance code for telling story of delta emergence during third COVID wave in CO |
|Vx data merge|Sheet from Rachel with CIIS data attached||Merge vaccination data to CEDRS data
||
|**RETIRED PROGRAMS:** | |
| OLD_Check.CEDRS_view| CEDRS_view_fix; B6172_fix; COPHS_fix| *N/A*|Run data checks on CEDRS view|
|RFI.DeltaVOC for MMWR|CEDRS_view_fix; & B6172_fix; & County_Population|MMWR_Cases; & MMWR_ICU|Generate numbers for **first** data request 


