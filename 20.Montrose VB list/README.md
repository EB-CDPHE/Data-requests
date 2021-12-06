## Background 
This data request came from Montrose Vaccine clinic via Alicia Cronquist. Alicia's [email](./Documents/Email_request_120321.pdf) was forwarded to me from Eduardo. 

On November 30th Heather Roth sent Lindsey Webb an email with a line list of 1779 individuals vaccinated at Montrose county vaccine clinic on November 12-13, 2021. Lindsey asked Breanna and Alicia if they could have someone look to see if any of these 1779 patients were cases in CEDRS. 

 are interested in learning what role kids going back to school have on COVID transmission within the household (HH) in particular, and the community in general. As there is no HH identifier in CEDRS, response to this data request is tortuous and complex. 

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
Here are the SAS programs used to respond to this data request:

|Run order|SAS program|
|---------|-----------|
|1.|Access.COPHS pulls data from hosp144 COPHS and curates it.|
|2.|FIX.COPHS edits data in COPHS.|
|3.|RFI.HH_transmission.sas creates household dataset and analysis variables and generates response.|

Sections of the RFI.HH_transmission.sas code

### **1. Check the filter variables**

Cases in CEDRDS_fix dataset need to be filtered by `ReportedDate`, `CountyAssigned`, and `LiveInInstitution`. There were no missing observations for `ReportedDate`. `CollectionDate` was missing for almost 23,000 records and so was not used as a filter. The number of records with `"01SEP20"d LE ReportedDate LE "01NOV20"d` OR `"01SEP21"d LE ReportedDate LE "01NOV21"d` was 181,960 (on 11/22/21).  N=103 records where `CountyAssigned="INTERNATIONAL"` were filtered out. And the nearly 35,000 records where `LiveInInstitution="YES"` were excluded as well.

The filters were applied to CEDRS_Fix dataset to create the [CEDRS_Filtered dataset](Documents/PROC%20contents.CEDRS_Filtered.pdf). 


### **2. Evaluate various pieces of HH address**

Either address or lat/long could be used to group cases into "Households". Address has multiple components, namely street address, unit number, city, State, zipcode, and county. Each of these elements were evaluated regarding completeness on the CEDRS_Filtered data.

|HH element|Description of element|Number missing|
|----------|-----------------------|--------------|
|Address1|Street address|776|
|Address2|Unit number|166,124|
|AddressActual|Don't know what this field is|170,587|
|Address_City|City|462|
|Address_CityActual|DK what this field is|170,587|
|Address_State|State|2992|
|Address_Zipcode|Zip code|646|
|CountyAssigned|County|0|
|Address_Latitude|Lat Long|7200|
|Address_Longitude|Lat Long|7200|

Over 7000 records are missing Lat / Long so it was decided to define HH based on address components. Here is a summary of completeness of the various address components:

![missingdata](Images/Address2.jpg)

Almost 98% of the records have data for all address components. Zipcode will not be used to define HH and only cases where State=CO will be used. **Therefore, HH is defined by unique value for Address1, City, and County.**

Some minor data edits were made. Specifically:
1. If Address1='' and Address2^='' then Address1=Address2;
2. If Address1='0' then Address1='';
3. if Address1 in ('NO ADDRESS PROVIDED', 'N/A', 'UNK', 'UNKNOWN') then Address1='';

A lot more data cleaning could be done, particularly with ZipCode data and missing State values. Some easy fixes would be to focus on the handful of records missing City but have Address and State or Zipcode data. The city can be easily obtained by googling the street address. 

### **3. Filter dataset again based on complete address components**
The CEDRS_Filtered dataset is filtered again, keeping only those records with complete address components (Address1, City, and County). Also, the 17 records where `Age_at_Reported=.` are excluded. The [CEDRS_Addresses](Documents/PROC%20contents.CEDRS_Addresses.pdf) dataset contains 178,093 cases.


### **4. Eligible Households**

The primary definition of a HH is based on Address1. County and City provide the context for this field to ensure Address1 is unique. CEDRS_Addresses was sorted by County, City, and Address1. A preview of the data was skimmed. Several data issues were noted with Address1. Here are the findings:

Findings:
````diff
+/*------------------------------------------------------------------------------------------*
+ |FINDINGS:
+ | There are several examples of HH's with slightly different values for Address1
+ |    For example:
+ |    "4037 W 62ND PL"  vs  "4037 W 62ND PL 652563542"
+ |    "4237 62ND PL  vs "4237 W 62ND PL"  vs "4237 WEST 62ND PLACE"
+ |    " 5005 W 61ST DR"  vs  " 5005 W.61ST.DR."
+ |    " 6065 UTICA"  vs  " 6065 UTICA ST"
+ |    "6288 NEWTON COURT"  vs  "6288 NEWTON CT"
+ |    "2320 HANDOVER ST"  vs  "2320 HANOVER ST"
+ |
+ |    ALSO:  150 N 19TH AVE (in BRIGHTON) is Adams County Sheriff's Detention Facility.
+ |    FIX: Set Live_in_Institution = 'Yes'
+ |    Should investigate other addresses that have >10 cases per Address1.
+ *--------------------------------------------------------------------------------------------*/
````
These are only a few examples of the types of data issues with Address1. At this time, these data issues have been ignored. For the majority of the cases though, it was deemed that Address1, in the context of County and City, was a sufficient tool for defining HH.

The CEDRS_Addresses data was thus grouped based on County, City, and Address1 to create "Households". HH with only a sigle case were excluded.

**Here is the distribution of cases per HH:**

![Num_Cases_per_HH](Images/Num_Cases_per_HH2.png)

It was decided to exclude HH with more than ten cases. Thus, eligible HH were those that had 2-10 cases per HH. There was a total of 61,309 cases in the 24,519 eligible HH.

### **5. Defining Clusters** 

Cases within a HH were grouped based on how they clustered in time. So a case that was reported within 30 days of the previous case was considered to be part of the same "cluster". There were a total of 30,988 clusters with the eligible HH.

**Here is the distribution of clusters per HH:**

![Num_Clusters_per_HH](Images/Num_Clusters_per_HH2.png)

###  **6. Creating an analysis variable**
Over a quarter of the HH had two clusters of cases, i.e. cases that were more than 30 days apart. Nearly three quarters had only a single cluster of cases.  The data request was to look at the proportion of clusters that began with the various age groups.   

|Abbrev.|Label|Age range|
|---------|-----|------------|
|i or I|infants|0-4 year olds|
|k or K|kids|5-11 year olds|
|t or T|teens|12-17 year olds|
|a or A|adults|18-15 year olds|

Thus, each cluster has a variable, `AG`, which displays the cases by Age Group in the order in which they were reported. For HH cases in Fall 2020, the AG variable is all lower case letters. Whereas for Fall 2021, the AG variable is all upper case letters. 

**Here is an exerpt of the HH data:**

![ListAG](Images/ListAGs.jpg)

#
The list of variables and their attributes for the final dataset is [HERE](Documents/PROC%20contents.HHcases.pdf).


## Response
Response was shared with Eduardo and Alicia via Google Slides:

https://docs.google.com/presentation/d/12aJxnbAFpz1XrXOR8NyD1DXJisqfUAT8gyXR-TKEWiQ/edit?usp=sharing


#
**Issues:**
# Oh! Where do I begin??!! 
* Definition of a HH? Single family homes only? Should we exclude apartment complexes? If not, is each apartment a separate HH or should the entire apartment complex be a single HH?
* Almost 3000 cases were missing data for State. Many of these could be CO households. Most of these have Zipcode data. If Zipcode data was cleaned and converted to numeric, it could easily be used to impute State=CO when Zipcode was 80000-80700.
* Zipcode data needs to be cleaned.

