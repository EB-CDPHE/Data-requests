## Background 
Alicia received this data request from Christy Smith-Anderson, Pediatrician from Children's Hospital Colorado (CHCO) and Lisa DeCamp. The request was captured in a google doc and shared with me on 1/21/22 by Eduardo. Here is the doc: [Jan14Request](./Documents/Data_request_doc_011422.pdf). 

**Population**:  Confirmed COVID cases (not probable) in Colorado minors (0-<18 years old).   **Data requested**: Number and percent of cases between March 1, 2020 and August 30, 2021. **Groups**: Race and Ethnicity. And three time periods:
* Time Period 1:   3/1/20 - 9/30/20
* Time Period 2:  10/1/20 - 3/31/21
* Time Period 3:   4/1/21 - 8/31/21


## Code
Here are the SAS programs used to respond to this data request:

|Run order|SAS program|
|---------|-----------|
|1.|[Access.CEDRS_view](../0.Universal/SAS%20code/Access.CEDRS_view.sas) pulls data from dbo144 COVID19 and curates it.|
|2.|[FIX.CEDRS_view](../0.Universal/SAS%20code/Fix.CEDRS_view.sas) edits data in CEDRS.|
|3.|[RFI.Pediatric_cases.sas](./SAS/RFI.Pediatric_cases.sas) filters CEDRS data to population defined above.|

The RFI.Pediatric_cases.sas program filters CEDRS data, explores the variables, generates the two response tables (cases by Ethnicity and cases by Race) and outputs data into Tableau directory.

Viz and data tables are also constructed in Tableau workbook.

### "Pediatric cases by race" is the Tableau workbook with final charts and tables.
The workbook has two worksheets for the Ethnicity viz - a bar chart and a stacked bar chart. The bar chart worksheet was duplicated as a crosstab to generate the data table. There is also a worksheet for the Race viz and it's corresponding data table.

A copy of the workbook has been placed on the J: drive in this directory: J:\Programs\Other Pathogens or Responses\2019-nCoV\Tableau

## Response
I copied images of the two Ethnicity charts, the one Race chart, and the two data tables in the Google doc. Here is the link to the Google file [Jan24Response](https://docs.google.com/document/d/1Lqd1g-cuRHGaXNH4M19b8MaWCwmI1ue9H2m0DCzFQBU/edit#heading=h.vo6r01jlzrtw).  


##
**Issues:**

* None so far. Oh, except that I'm doing the 'analyze and run' thing.




