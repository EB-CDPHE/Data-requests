## Background 
This data request came from Eduardo via [email](./Documents/Email_request_120321.pdf).  

**Population**: Confirmed Cases in Dr Justina-Prod data table.   **Data requested**: Proportion of confirmed cases that were HCW by month.   **Groups**: Month sample collected was requested. Since Specimen collection date in Dr Justina is missing for half of the records, month per ReportedDate (CEDRS) was used. 


## Code
Here are the SAS programs used to respond to this data request:

|Run order|SAS program|
|---------|-----------|
|1.|[Access.CEDRS_view](../0.Universal/SAS%20code/Access.CEDRS_view.sas) pulls data from dbo144 COVID19 and curates it.|
|2.|[FIX.CEDRS_view](../0.Universal/SAS%20code/Fix.CEDRS_view.sas) edits data in CEDRS.|
|3.|[Access.DrJustina.sas](../0.Universal/SAS%20code/Access.DrJustina_prod.sas) access Patient data table on dphe146 and curates data.
|4.|[RFI.Boulder_HCW.sas](./SAS/RFI.Boulder_HCW.sas) checks and fixes DrJustina Patient data, adds CEDRS date variable, and summarizes the proportion of confirmed cases that were HCW.|

Sections of the RFI.Boulder_HCW.sas code

### **1. Check Dr Justina Patient data**

`CDPHE_Case_Classification=confirmed` for >90% of patients. Patients with other response options are excluded. 

`HCW=missing` for >98% of confirmed cases. Therefore, values of the four Occupation variables are scanned for "healthcare" and used to impute missing values of HCW. Occupations, e.g. Agriculture, Grocery, and Retail, all have sub-categories, one of which is "Healthcare". If HCW was missing and the patient had a sub-category of 'healthcare' then HCW was set to 'yes'.
cases.

`Specimen_Collection_Date = missing` for about half of patients.


The variable names and their attributes for the combined dataset are in the [PROC_CONTENTS](./Documents/PROC_Contents.HCW_CEDRS.pdf)


### **2. Add ReportedDate from CEDRS to Dr Justina Patient data on confirmed cases**

Access and curate CEDRS data and keep case status and date variables. Sort both datasets and merge using ProfileID and EventID.

##
### **3. Calculate proportion of cases that are HCW by month in 2021**
##
There were 6,813 HCW that were confirmed cases in 2021, which is about 1.5% of all cases. 


## Response
Tables and charts were added to Google slides document and shared with Eduardo 12/17/21. Here is the link:

https://docs.google.com/presentation/d/1HXcgunonnQq0SGtmncNtTJhXbHlGYdRk4DLFaDqKZdM/edit#slide=id.p

Alicia Cronquist sent an [email response](Documents/Email_response_122021.pdf) on 12/20/21.

##
**Issues:**
* What type of join to use for Dr J data and CEDRS data? Should I add HCW variable to CEDRS cases? Or am I adding CEDRS data, e.g. ReportedDate, to Dr J data?

* HCW indicator variable is missing for >90% of patients.

* HCW_Type variable is not useful for measuring case exposure.

* Didn't add county filter, e.g. Boulder county. Not sure if this request was for all of Colorado or just Boulder county.


