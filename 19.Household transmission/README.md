## Background 
This data request came from Rachel Herlihy via Alicia Cronquist. Alicia's [email](Documents/Email_request_111021.pdf) was forwarded to me from Eduardo. 

They are interested in learning what role kids going back to school have on COVID transmission within the household (HH) in particular, and the community in general. As there is no HH identifier in CEDRS, response to this data request is tortuous and complex. 

**Population**:  Confirmed and probable cases in CEDRS with `ReportedDate` between September 1 - November 1 in 2020 and 2021.  **Data requested**: HH's with 2-10 cases reported in CEDRS.   **Groups**: School start for 2020 versus 2021. Age groups were:
* 0-4 year olds, "infants"; 
* 5-11 year olds, "kids"; 
* 12-17 year olds, 'teens'; 
* 18-115 year olds, 'adults'

The following specific questions were asked:
1. Among HH that had 2 or more cases, how frequently was the initial case reported in a minor (0-17 years old)?
2. Proportion of multi-case HH's where minor was first case by Age Group, i.e. infant, kid, teen.
3. Was this proportion different in Fall 2021 compared to Fall 2020? 

## Code
Ugh. Where to begin.

|Run order|SAS program|
|---------|-----------|
|1.|Access.COPHS pulls data from hosp144 COPHS and curates it.|
|2.|FIX.COPHS edits data in COPHS.|
|3.|RFI.HH_transmission.sas generates response.|

Hm. 1. Filter cases by date range, county, and live in institution.Then 2. assess completeness and quality of address components, i.e. address1, address2, city, zip, state, and county.
And then, hm, how to define HH.



The macro creates a SAS dataset with rates and rolling averages. Tableau was used to connect to this data, idenity the 'high mortality period', and explore relationships between 14 day moving average for mortality rate and selected variables. 

**NOW that I think about it though, this was NOT a valid approach. SAS dataset collapses patient-level CEDRS dataset into a DATE-level dataset to calculate daily rates by group-processing and keeping last observation in group (ReportedDate). Thus, any patient-level data, such as age, is from the last obs in the group only.**

## Response
That's a bummer because I built a beautiful dashboard with highlighted findings.


#
**Issues:**
# Oh! Where do I begin??!! 
* maybe here at home

