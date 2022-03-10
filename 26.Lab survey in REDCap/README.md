## Background 
Alicia Cronquist appointed Eduardo and I to take the place of Breanna Kawasaki and Millen Tsegaye in managing the COVID19 section of the 2022 Statewide Lab Survey. The email is [here](./documents/Email_022222.pdf). This annual web survey of clinical labs has been managed by Colleen McGuinness and Erin Yonkin. Here is link to the project management sheet:  
https://docs.google.com/spreadsheets/d/1HYz5W6Ev-tWtbUFrEoUWhSFbDfBjxVnvOr8XS_oq7e4/edit#gid=1257411649

## Questionnaire
The link to the 2021 Statewide Lab Survey is [here](Documents/2021%20Statewide%20Lab%20Survey.pdf).

## Question Map
I created a "question map" to document revised wording and structure of survey questions. This map lists "items" for introductory filter questions, off-site testing, on-site test type, PCR testing platform, and reporting of results.

https://docs.google.com/spreadsheets/d/1BIw2B3flJzQVBftiCdzmaRvDQa3Vo215uexxPv4c-M8/edit#gid=0

## Flow diagram
Based on the question map, I developed a flow diagram to lay out the branch logic to be used for the survey items. This was created in Diagram.NET. 
1. Diamonds are branching questions 
2. "Skips" come out bottom of diamonds, follow-up questions take the high road.
3. Solid arrow is direct progression of questions. Arrows out of diamonds show branching logic.
4. Dash arrow shows branch logic for question items that are not contiguous in survey flow
5. Items are generally marked sequentially. Decimal is used to denote follow-up to parent question. Letter suffix is used to denote question part to a common stem.



Here are the steps to navigate to the data at State Demography Office (SDO):

1. Data by Topic:  Population
2. Population Spreadsheets: Download population data for all geographies



3. County Population Estimates by Race/Ethnicity, Age and Sex, 2010 to 2020



Then the following steps were taken to process the downloaded demographic data:
1. download csv. Default filename is "race-estimates-county.csv" 
2. open CSV file, delete ID column, Rename Tab to DATA --> then save as Excel file
3. Save as Excel file in INPUT folder (of this data request folder)

The SAS dataset County_Race_POP2020 is created via this section of code:
````diff
+DATA County_Race_POP2020; length Race_Ethnicity $ 22 ;  set mysheets.DATA;
+   where year=2020;
+   rename sex=Gender;
+   rename count=Population;
+
+* create single Race - Ethnicity variable *;
+   if Ethnicity = 'Hispanic Origin' then Race_Ethnicity='Hispanic Origin';
+   else Race_Ethnicity=Race;
+run;
````
##
Here is the 2020 population count by single Race-Ethnicity:

Since the SDO County population data uses County FIPS codes only, another temp dataset that links County FIPS codes with County names was used to join with County_Race_POP2020. The final SAS dataset is stored permanently in my Tableau dashboard directory:  DASH.County_Population   This data table includes County level population estimates by gender (M|F), Race-Ethnicity, and age (1 yr intervals).


### RFI.Hosp_rates_Race.sas.
The COPHS_fix dataset is filtered by `Hosp_Admission` where dates are between 01OCT2020 and 01DEC2022 per request and to exclude invalid date values. The indicator variable `CO`for Colorado residents was modified in the COPHS.fix code and used to filter data to only Colorado residents. Only selected variables are retained.

Here is the distribution of hospitalizations by Ethnicity:

**NOTE: In the creation of a single Race-Ethnicity variable, Race for those that are not Hispanic or Latino was based on race for Non-Hispanics and also those with unknown or unreported Ethnicity.**

##
Here is the case count, based on hospital admissions, by single Race-Ethnicity:

The final SAS dataset is stored permanently in my Tableau dashboard directory:  DASH.COPHS_fix

## "Hospitalization rates (7d) by Race/Ethnicity" is the Tableau workbook used to generate final charts

The workbook connects to the two data sources described above:
1. County_Population
2. COPHS_fix

Here is a summary of the sheets and dashboards in Hospitalization rates (7d) by Race/Ethnicity workbook.

|Tab title|Tab type|Description|
|---------|--------|-----------|
|Population|Sheet|Check that population counts by single Race/Ethnicity match SAS table|
|Cases|Sheet|Check that hosp counts by single Race/Ethnicity match SAS table|
|Case rates|Sheet|Over lay of bar chart of hospitalization and population counts by Race/Ethnicity
|Case rate calc|Sheet|Calculation of overall hospitalization rate; i.e. number of hospitalizations per 100,000 people by Race/Ethnicity|
|Case rate by month|Sheet|Hospitalization rate by month of hospital admission
|Case rate 7d plot|Sheet|Line chart of 7 day moving average of hospitalization rate by Race/Ethnicity|
|Case rate 14d plot|Sheet|Line chart of 14 day moving average of hospitalization rate by Race/Ethnicity|
|Case rate 30d plot|Sheet|Line chart of 30 day moving average of hospitalization rate by Race/Ethnicity|
|HospRate|Dashboard|7d average of hospitalization rate by Race/Ethnicity with floating color legend and source footnote.
|HospRate_w_Denom|Dashboard|7d average of hospitalization rate by Race/Ethnicity with floating color legend, source footnote, and denominator values.


## Response
Several viz options were dumped in a slide show and shared with Alicia and Eduardo: 

https://docs.google.com/presentation/d/1XGIxXtwWbv_2lNuf-Ha9Wr0tHw72OqKCjo_DVGIZW9k/edit#slide=id.g116e0aa68a5_0_22

The final viz chosen by RH was this one:
##
![FinalViz](./Images/HospRate30d.png)
##

**Issues:**
* Already mentioned in code section. 




