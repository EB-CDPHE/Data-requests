# Data-requests

## Background: 
This request is for data needed to complete a table in the presentation [B.1.617.2 in Colorado](https://docs.google.com/presentation/d/10v9o1mwOVWfGtpJpnd5A6Gr5hDkt4GlVSTkwXSMTLhE/edit?ts=60f1ca9b#slide=id.gdf56bc7d45_8_0). **Population**:  Confirmed and probable cases with reported dates after April 5, 2021 (inclusive). Any cases with delta variant. **Groups**: Colorado regions defined as Mesa county versus all other counties ("ROC"). **Data requested**: number of cases; median and mean age, age range, gender, hospitalization rate; mortality rate; percent reinfection, percent vaccine break-through case.  An earlier version of the table asked for outcomes by age (<70 yo and 70+ yo).  The earlier version requested data for the same outcomes and groupings but for the population of delta variants isolated from confirmed and probable cases.
#
## Steps taken to get data for revised table
| <p align="left">Run order</p> | <p align="left">SAS programs used for data request</p> |
| --- | ------------------------------------------------------------------------------------ |
|1| Run Access.CEDRS_view to pull data from dphe144 CEDRS_view. Creates CEDRS_view |
|2| Use Check.CEDRS_view for data checks. Output informs edits made in Fix.CEDRS_view|
|3| Run Access.zDSI_Events to access Events table and get Age. Creates zDSI_Events.read|
|4| Run FIX.zDSI_Events to create Age_in_Years variable|
|5| Run FIX.CEDRS_view to edit data in CEDRS_view and add Age_in_Years. Creates CEDRS_view_fix
|6| Run Access.B6172 to pull sequencing results for Delta variants.
|7| Use Check.B6172 for data checks. Output informs edits made in Fix.B6172|
|8| Run FIX.B6172 to edit data in B6172_Read. Edits include de-dup, county, age. Creates B6172_fix.
|9| Run RFI.DeltaVOC_in_Mesa to generate numbers for the four columns in the table.  
|   | It makes use of the output from these SAS programs that get automatically run:
        1) Mesa.formats.sas
        2) Key_merge.COPHS.CEDRS.sas

#             
## SAS Programs in this folder:

| Program name    | Input Dataset  | Output Dataset   | Purpose                                  
| --------------- | -------------- | ---------------- | ---------------------------------------| 
| EpiCurve.DeltaVOC_in_Mesa|**???**|*N/A*|Generate output used in Excel to chart epi curve|
|Mesa_formats| *N/A* | *N/A* |Create user defined formats
|RFI.DeltaVOC_in_Mesa|COVID.CEDRS_view_fix; & COVID.B6172_fix|Not_Mesa144; Mesa144; Not_Mesa_B16172; Mesa_B16172|Generate numbers for table in presentation
||
|**RETIRED PROGRAMS:** | |
| OLD_Check.CEDRS_view|*N/A*|*N/A*|Code for data checks; new version moved to parent directory|
| OLD_Fix.B6172|*N/A*|*N/A*|Code for data checks; new version moved to parent directory|

