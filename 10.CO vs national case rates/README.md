## Background 
This data request is to see how Colorado cases compares to US national case load.  

DATA SOURCE:  
https://www.kaggle.com/antgoldbloom/covid19-data-from-john-hopkins-university/version/126





Since non-public schools are not required to report COVID19 cases, the data will have to be county-level measure of disease burden.
**Population**:  Confirmed and probable cases in CEDRS per 100K population. **Groups**: All Colorado counties. All time and also restricted to FY20-21. **Data requested**: Case rate per 100K by county for all time and FY20-21 sorted in descending order. 

## Response
Final response was delivered as two CSV files.
1. [AllCaseRate](AllCaseRate.csv)
2. [FY20-21CaseRate](FY20-21CaseRate.csv)
#

## Code
#### The SAS program used to generate the response was [RFI.Cases_by_County.sas](RFI.Cases_by_County.sas). This may also require running [Access.Population](../Access.Populations.sas) to obtain COVID.Population data if not already available.
#

**Issues:**
* Update the Access.Population program to point to 2020 census data instead of 2019 data. 

