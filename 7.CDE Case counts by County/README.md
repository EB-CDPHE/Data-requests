## Background 
This data request came from DeLilah Collins, Assistant Director at Colorado Department of Education (CDE). They are applying for a grant ("Emergency Assistance to non-public schools" and the application requires data on COVID. Non-public schools however are autonomous from the State. Data needs to address:
1. Which non-public schools are most impacted by COVID19?
2. What is the economic impact of COVID19 in these communities?

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

