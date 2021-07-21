# Data-request for MMWR Notes from the Field article

## Background: 
This request is for data needed to complete the table in the MMWR [Notes from the Field](https://docs.google.com/document/d/1Jla02O-FwNHoCOz3zqUEXd80KRmpGzljFKM7hfSf7T4/edit?ts=60f10e65).  **Population**:  Confirmed and probable cases with collection dates between April 27 - June 6, 2021 (inclusive).  **Outcomes**: case rate per 100k; hospitalization rate; ICU admission rate; case fatality ratio (for all cases and hospitalized cases only).  **Groups**: Colorado regions defined as Mesa county versus all other counties ("ROC"). An earlier version of the table asked for outcomes by age (<70 yo and 70+ yo).  
First request: Same outcomes. Grouping was for <70 yo vs 70+ yo by region (Mesa vs ROC). The population was all cases (confirmed and probable) and also population of delta variants.
Second request: see above description. Drops age grouping and population of delta variants.
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
|RFI.COVID_MMWR|CEDRS_view_fix|MMWR_Cases; & MMWR_ICU|Generate numbers for **second** data request table
|MMWR_formats| *N/A* | *N/A* |Create user defined formats
|Key_merge.COPHS.CEDRS|dbo66.Profiles; & COVID.COPHS_fix; & MMWR_cases|MMWR_ICU|Merge ICU data from COPHS into MMWR_Cases
|Delta_Story.sas| COVID.CEDRS_view; COVID.B6172_fix; COVID.County_Population | MMWR_cases | free lance code for telling story of delta emergence |
|Vx data merge|Sheet from Rachel with CIIS data attached||Merge vaccination data to CEDRS data
||
|**RETIRED PROGRAMS:** | |
| OLD_Check.CEDRS_view| COVID.CEDRS_view| *N/A*|Run data checks on CEDRS view|
|RFI.DeltaVOC for MMWR|CEDRS_view_fix; & B6172_fix; & County_Population|MMWR_Cases; & MMWR_ICU|Generate numbers for **first** data request 


