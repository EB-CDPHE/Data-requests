## Background 
Rachel Herily requested, via Alicia Cronquist, a slide of daily hospitalizations per 100,000 by Race - Ethnicity. The email forwarded to me from Eduardo is [here](Documents/Email_request_021822.pdf).

**Population**:  COPHS hospitalization data for Colorado residents.   **Data requested**: 7 day moving average of the hospitalization rate (new hosp admits per 100,000) for COVID cases hospitalized between October 1, 2020 and the present (February 7, 2022 to account for two week lag). **Groups**: Race and Ethnicity. These two variables were combined to be in alignment with the demographic population data:
* Hispanic orgin (all races)
* White (Non-Hispanic origin)
* Black (Non-Hispanic origin)
* Asian/Pacific Islander (Non-Hispanic origin)
* American Indian (Non-Hispanic origin)


## Code
Here are the SAS programs used to respond to this data request:

|Run order|SAS program|
|---------|-----------|
|1.|[Access.COPHS](../0.Universal/SAS%20code/Access.COPHS.sas) pulls data from dbo144 Hosp.COPHS_tidy and curates it.|
|2.|[Check.COPHS](../0.Universal/SAS%20code/Check.COPHS.sas) checks COPHS data quality.|
|3.|[FIX.COPHS](../0.Universal/SAS%20code/Fix.COPHS.sas) edits COPHS data.|
|4.|[GET.CO_Population_Race.sas](./SAS/GET.CO_Population_Race.sas) downloads data from Colorado's State Demography Office to obtain 2020 population counts by County, Age, Race, and Ethnicity.|
|5.|[RFI.Hosp_rates_Race.sas](./SAS/RFI.Hosp_rates_Race.sas) to prep COPHS data for use in Tableau and to generate basic counts of cases and population by single Race-Ethnicity categories.

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




