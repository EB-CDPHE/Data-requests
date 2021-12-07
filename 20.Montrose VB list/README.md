## Background 
This data request came from Montrose Vaccine clinic via Alicia Cronquist. Alicia's [email](./Documents/Email_request_120321.pdf) was forwarded to me from Eduardo. 

On November 30th Heather Roth sent Lindsey Webb an email with a line list of 1779 individuals vaccinated at Montrose county vaccine clinic on November 12-13, 2021. Lindsey asked Breanna and Alicia if they could have someone look to see if any of these 1779 patients were cases in CEDRS. 

**Population**: First population consisted of 1,779 individuals vaccinated at Montrose vaccine clinic on November 12-13, 2021. Population #2:  Confirmed and probable cases in CEDRS.  **Data requested**: Intersection of the two populations.   **Groups**: Gender, Age, Date vaccinated, and Vaccine manufacturer. 


## Code
Here are the SAS programs used to respond to this data request:

|Run order|SAS program|
|---------|-----------|
|1.|[Access.CEDRS](../0.Universal/SAS%20code/Access.CEDRS_view.sas) pulls data from hosp144 COPHS and curates it.|
|2.|[FIX.CEDRS](../0.Universal/SAS%20code/Fix.CEDRS_view.sas) edits data in COPHS.|
|3.|[RFI.Montrose_VxCases.sas](./SAS/RFI.Montrose_VxCases.sas) creates dataset from Montrose spreadsheet and of individuals on that list that were in CEDRS.|

Sections of the RFI.Montrose_VxCases.sas code

### **1. Import spreadsheet and curate line listing data from Montrose Vaccine clinic**

`Patient_Name` has a format of Last name,First name (#). Code in this section parses patient name into last name, then first name, then in 'extra' field to hold numeric id, stripped of parentheses.
Use DOB column to create birthdate var with format YYYY-MM-DD which is consistent with format of DOB in CEDRS66.Profiles. Create new calculated variable "Age at Vaccination". Finally, create KEY variable by concatenation of Birthdate:Last name:First name. This KEY variable will be used for match merging to CEDRS cases.

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
* No column on Montrose Vaccine clinic line listing contained ProfileID or EventID that could link individuals to CEDRS directly.

* A make-shift key was made by concatenating DOB:Last_Name:First_Name. No effort was made to assess the performance of this key for matching / merging records from line listing to CEDRS. It's possible that some were missed.


