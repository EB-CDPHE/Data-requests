## Background 
This data request on waning immunity came from Rachel S. There is email discussion between her and Debashis Ghosh. The outcome variable is breakthrough cases.


**Population**:  Confirmed and probable cases in CEDRS for 12/14/20 through 9/23/21. **Independent variables**: Time since vaccination and also age, gender, vaccine recieved. **Data requested**: Build a logistic regression model on outcome (Breakthrough case) by time since vaccination. 

## Response
Final response was delivered as two CSV files.
1. [AllCaseRate](AllCaseRate.csv)
2. [FY20-21CaseRate](FY20-21CaseRate.csv)
#

## Code
#### Rachel S. had a dataset on dphe144 server. The SAS program [Access.TimeSinceVax.sas](../Access.TimeSinceVax.sas) toused to generate the response was [RFI.Cases_by_County.sas](RFI.Cases_by_County.sas). This may also require running [Access.Population](../Access.Populations.sas) to obtain COVID.Population data if not already available.
#

**Issues:**
* Update the Access.Population program to point to 2020 census data instead of 2019 data. 

