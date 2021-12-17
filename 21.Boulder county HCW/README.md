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

`CDPHE_Case_Classification=confirmed` for >90% of patients. Patients with other response options are excluded. `HCW=missing` for >98% of confirmed cases. Therefore, values of the four Occupation variables are scanned for "healthcare" and used to impute missing values of HCW. Occupations, e.g. Agriculture, Grocery, and Retail, all have sub-categories, one of which is "Healthcare". If HCW was missing and the patient had a sub-category of 'healthcare' then HCW was set to 'yes'.
cases.

The variable names and their attributes for the Montrose vaccine clinic line listing are [here](./Documents/PROC_Contents.Montrose_Fix.pdf). 


### **2. Link ProfileID and KEY variable (DOB:LAST:FIRST) and filter on CEDRS cases**


<u>NOTES for CEDRS66.Profiles dataset:</u>
````
* CEDRS66.Profiles has ProfileID AND DOB, Last Name, First name
* DOB, Last Name, First name are the components to the KEY variable
* DOB needs to be a character format and not a SAS date var
* KEY variable has length 85 and ProfileID has length 15
````
   ==>  Profiles_Key dataset

<u>NOTES for CEDRS_view dataset:</u>
````
* COVID.CEDRS_view_fix has ProfileID for all cases
* Filter out cases not assigned to a Colorado county
* Keep selected variables from CEDRS
````
  ==>  CEDRS dataset

<u>NOTES for merged dataset of Profiles and CEDRS:</u>
````
* SORT Profiles_Key and save as Profiles_sort
* SORT CEDRS and save as CEDRS_sort
* Merge Profiles_sort and CEDRS_sort on ProfileID.
* KEEP only records only from CEDRS 
````
   ==>  CEDRS_key  dataset

<u>NOTES for merged dataset of Montrose and CEDRS:</u>
````
* SORT Montrose_fix and save as Montrose_DOB
* SORT CEDRS_key and save as CEDRS_DOB
* Merge Montrose_DOB and CEDRS_DOB on KEY variablbe (DOB:LAST:FIRST).
* KEEP records from both Montrose list and CEDRS 
````
   ==>  Montrose_cases  dataset

Here is the link to the variable names and their attributes for the [Montrose_cases](./Documents/PROC_Contents.Montrose_Cases.pdf) dataset.

##
### **3. Characteristics of line listing:**
##
There were 1,779 individuals vaccinated on November 12 and 13. The number vaccinated each day was nearly equal. The majority vaccinated were female (55%) and received Moderna (92%). About 80% were 50 plus years old.

![LineListing](./Images/Vaccinated.png)

##
### **4. Analysis of Montrose cases**
##
The 159 vaccinated individuals that have records in CEDRS can be found here: [Montrose_cases.csv](Output%20data/Montrose_cases.csv). 

The vast majority of these 159 individuals are in CEDRS with a `ReportedDate < 11/01/21`. Here is the frequency distribution by month reported to CEDRS:

![image1](Images/PriorCases2.jpg)

Here is the listing of the 16 records where `ReportedDate > 11/01/21`. 

![VC](Images/VaccinatedCases2.png)


And the proportion of these recent cases by age, gender, and vaccine manufacturer:

![VxCases](Images/VxCasesFreq2.png)

## Response
Response was shared with those on the email chain via [email](Documents/Email_response_120521.pdf) on 12/5/21.  

And documentation and additional information were shared on 12/6/21 via GitHub link:

https://github.com/EB-CDPHE/Data-requests/blob/f582eea2ad62dcdf35bf76a89b6b6ae39d7777b8/20.Montrose%20VB%20list/README.md


##
**Issues:**
* What type of join to use for Dr J data and CEDRS data? Should I add HCW variable to CEDRS cases? Or am I adding CEDRS data, e.g. ReportedDate, to Dr J data?

* HCW indicator variable is missing for >90% of patients.

* HCW_Type variable is not useful for measuring case exposure.


