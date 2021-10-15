## Background 
This data request came thru Eduardo. The first request was for the death rate in Moffat county and how it compares to Colorado as a whole. Later, they also asked for hospitalization rate in Moffat county and how that compared to all of Colorado. 

**Population**:  Confirmed and probable cases in CEDRS with `Outcome='Patient Died'` (Deaths) per 100K population.  **Groups**: Moffat county and all Colorado counties. Data was asked for two time periods: all dates and since June 1, 2021.  **Data requested**: Case rate per 100K by county for all time and FY20-21 sorted in descending order. 

## Response
Final response was delivered snippet of SAS output placed in chat to Eduardo.

#

## Code
The SAS program used to generate the response was [RFI.Cases_by_County.sas](RFI.Cases_by_County.sas). This may also require running [Access.Population](../Access.Populations.sas) to obtain COVID.Population data if not already available.
#

**Issues:**
* I wasn't available to respond to second data request for Moffat county which was for the outcome hospitalization rates. 

