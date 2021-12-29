## Background 
With the rapid onset of Omicron variant, case investigations are lagging and therefore CEDRS is not able to provide the most recent stats of this new wave. Therefore, Alicia shared a brainstorming document on how we can make use of ELR data.


 
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

* Address data is very messy. Little effort has been made to clean it. 
* NOTE for example the first record where Address1='5400 SHERIDAN BLVD'. If print out all records with this address it can be noted there are three different cities. Not sure if this is the same physical location or not.
* NOTE for example that the second record where Address1='5400 SHERIDAN BOULEVARD' is most likely the same physical location as the first record but is defined here as a distinct HH. This issue occurs quite commonly. So the number of cases per HH is a minimum and not an accurate count. 




