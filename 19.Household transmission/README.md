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

Sections of the HH.sas code
## Section 1:

**1. Check the filter variables**

Cases in CEDRDS_fix dataset need to be filtered by `ReportedDate`, `CountyAssigned`, and `LiveInInstitution`. There were no missing observations for `ReportedDate`. `CollectionDate` was missing for almost 23,000 records and so was not used as a filter. The number of records with `"01SEP20"d LE ReportedDate LE "01NOV20"d` OR `"01SEP21"d LE ReportedDate LE "01NOV21"d` was 181,960 (on 11/22/21).  N=103 records where `CountyAssigned="INTERNATIONAL"` were filtered out. And the nearly 35,000 records where `LiveInInstitution="YES"` were excluded as well.

The filters are applied to CEDRS_Fix dataset to create CEDRS_Filtered data. The full list of variables and their attributes for the CEDRS_Filtered dataset are listed [HERE](Documents/PROC%20contents.CEDRS_Filtered.pdf). 


Then 2. assess completeness and quality of address components, i.e. address1, address2, city, zip, state, and county.
And then, hm, how to define HH.



The macro creates a SAS dataset with rates and rolling averages. Tableau was used to connect to this data, idenity the 'high mortality period', and explore relationships between 14 day moving average for mortality rate and selected variables. 

**NOW that I think about it though, this was NOT a valid approach. SAS dataset collapses patient-level CEDRS dataset into a DATE-level dataset to calculate daily rates by group-processing and keeping last observation in group (ReportedDate). Thus, any patient-level data, such as age, is from the last obs in the group only.**

## Response
That's a bummer because I built a beautiful dashboard with highlighted findings.


#
**Issues:**
# Oh! Where do I begin??!! 
* maybe here at home

