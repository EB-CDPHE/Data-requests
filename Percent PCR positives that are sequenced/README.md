# Data-request for Specimens that have been sequenced 
## Background:
This request is for the proportion of specimens collected from confirmed and probable COVID cases.  **Population**:  Confirmed and probable cases with specimen create date or collection date from January 1, 2021 to present that have a positive PCR or other molecular assay result.  **Outcomes**: percent of positive specimens that have been sequenced.  **Groups**: Week of collection date (or create date) and type of laboratory that provided sequencing results, i.e. CDPHE lab or other lab.  

#

## Data sources:
Diagnostic testing is sequential and begins with specimen collection. The vast majority of specimens are tested for COVID using RT-PCR. Some are tested using other molecular assays. Those with positive test results are eligible for whole genome sequencing. Sequenced results include SARS2 variant type and "VOC" indicator (variant of concern). 

![Source_Data_Tables](images\SourceDataTables.png)



#
> What does this look like?
##

![Curated_Datasets](images/Curated%20datasets.jpg)
#

|     | <p align="left">Steps taken to get data for revised table</p> |
| --- | ------------------------------------------------------------------------------------ |
|1| Access.Specimens.sas program reads and curates data from dphe66 zDSI_LabTests.Specimen. |
|2| Access.Lab_TT229.sas program reads and curaates data from dphe6 zDSI_LabTests and filters on TestTypeID=229, which is for 'RT-PCR' tests. |
|3| Run Access.zDSI_Events to get Age. Creates zDSI_Events.read|
|4| Run FIX.zDSI_Events to create Age_in_Years variable|
|5| Run FIX.CEDRS_view to edit data in CEDRS_view_read, add Age_in_Years variable.  Creates CEDRS_view_fix
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
|RFI.MMWR_NFTF_Table1|CEDRS_view_fix; B6172_fix; COPHS_fix|MMWR_Cases & MMWR_ICU|Generate numbers for **first** data request table
|RFI.MMWR_NFTF_Table2|CEDRS_view_fix; B6172_fix; COPHS_fix|MMWR_Cases & MMWR_ICU|Generate numbers for **second** data request table


