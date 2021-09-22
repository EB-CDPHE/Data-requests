## Background 
This data request came from CDC Aggregate Data team for historical data in order to reconcile Colorado COVID cases and deaths in their aggregate dataset. Here is the [email](./CDC_email.pdf). The original request came in August 3, 2021. I was tasked with it on September 22, 2021.  The email contains the specific data elements requested. 

**Population**:  Confirmed and probable cases in CEDRS by ReportedDate. **Groups**: Case status (confirmed and probable) and Outcome (Patient died).  **Data requested**: Daily count of confirmed, probable, and total cases. Daily count of deaths for confirmed and probable cases, and total deaths. For each of these outcomes a cumulative daily total was calcualted. Daily change in cumulative totals was calcuated for total cases and total deaths. 

## Findings
At the time of this response, here are the calculated totals for the requested data:


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

