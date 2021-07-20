# Data-requests

## Background: 
This data request by the Governor's office is for information comparing hospitalization rates in Western Slope versus ROC. **Population**:  Hospitalized COVID-19 cases in CY2021. **Groups**: Western slope counties versus all other counties ("ROC"). **Data requested**: Hospitalization rate.
This was primarily a practice run for me as it was one of the first RFI's I responded to. The actual response came from Rachel S. See her slides here.
#
## Steps taken to get data for revised table
| <p align="left">Run order</p> | <p align="left">SAS programs used for data request</p> |
| --- | ------------------------------------------------------------------------------------ |
|1| Run Access.COPHS to pull data from hosp144 COPHS. Creates COPHS_read |
|2| Use Check.COPHS for data checks. Output informs edits made in Fix.COPHS|
|3| Run FIX.COPHS to edit data in COPHS. Creates COPHS_fix
|4| Run Access.Populations to obtain county population data. 
|5| Run RFI.Western_slope_hosp to generate hospitalization rates for Western slope counties and ROC.

#             
## SAS Programs in this folder:

| Program name | Input Dataset  | Output Dataset | Purpose                                
| --------------- |--------------|----------------|-----------------------------------| 
|RFI.Western_slope_hosp|COVID.COPHS_fix; & COVID.Populations| COVID_Hosp_CY21|Generate hospitalization rates
||


