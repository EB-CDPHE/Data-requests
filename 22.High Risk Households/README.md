## Background 
This data request came from Coffee and Data meeting. A request from Ginger is for a list of Households ("HH) that are considered "high risk" and should be prioritized for case investigation activities. There are some relatively good lists of large formalized group-housing situations, e.g. jails. However, there is not a good list of smaller, less formal, group-housing situations. In an effort to identify these HH, I reran exerpts of the previous "HH Transmission" analysis but this time just focusing on HH with >10 cases per HH.
 
**Population**: Confirmed and probable cases in CEDRS with  `Address_State=CO` and `Address1 and Address_City NOT missing`.  **Data requested**: List of HH with >10 cases.  **Groups**: LiveInInstitution='YES' vs NOT 'YES' (No and Unknown). 


## Code
Here are the SAS programs used to respond to this data request:

|Run order|SAS program|
|---------|-----------|
|1.|[Access.CEDRS_view](../0.Universal/SAS%20code/Access.CEDRS_view.sas) pulls data from dbo144 COVID19 and curates it.|
|2.|[FIX.CEDRS_view](../0.Universal/SAS%20code/Fix.CEDRS_view.sas) edits data in CEDRS.|
|3.|[RFI.High_risk_HH.sas](./SAS/RFI.High_risk_HH.sas) RFI.High_risk_HH.sas creates household dataset and analysis variables and generates datasets to export to Excel.|


## Response
Two SAS datasets were created and exported to Excel. One for HH's with >10 cases and the most recent case had value of `LiveinInstitution='YES'` and another tab for HH's with >10 cases and the most recent case had value of `LiveinInstitution NOT ='YES'`.  Here is the link to the Excel file: [HighRiskHH](./Output%20data/HighRiskHH.xlsx).  



##
**Issues:**

* Almost 3000 cases were missing data for State. Many of these could be CO households. Most of these have Zipcode data. If Zipcode data was cleaned and converted to numeric, it could easily be used to impute State=CO when Zipcode was 80000-80700.
######
* Zipcode data needs to be cleaned.
* Address data is very messy. Little effort has been made to clean it. For example, Address1='5400 SHERIDAN' has three different cities.




