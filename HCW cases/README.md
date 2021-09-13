## Background 
This data request came from Rachel H. via Breanna and Nisha. The request was specifically for Snowflake to be used to generate the proportion of COVID-19 cases that are healthcare workers and show this over time. **Population**:  Confirmed cases in Dr Justina that had a `Date_Opened` between October 1, 2020 and August 31, 2021. **Groups**: Healthcare workers (`HCW=1`) or Occupation contains 'healthcare' as a proportion of confirmed cases. **Data requested**: Proportion of confirmed cases that were healthcare workers by month. 

## Response
Final response was delivered via a few slides that can be seen [here](https://docs.google.com/presentation/d/1JiUm_GukAfzZLlpAABx0JAVU9GNQR_MyNJMTOy-enxA/edit?usp=sharing).
#
#### Snowflake query
`SELECT date_opened, hcw, hcw_type, direct_patient_care, occupation, case_id, event_id FROM DM_CO_PROD.DM.CASE_PATIENT_ALL WHERE patient_type = 'confirmed' AND (stub= 'no' OR stub is null)`
#
#### The SAS program used to generate the response was [RFI.HCW.sas](RFI.HCW.sas)

