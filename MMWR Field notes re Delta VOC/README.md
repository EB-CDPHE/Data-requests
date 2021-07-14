# Data-requests

### This request is for estimates needed to complete table in the MMWR Field report manuscript.

## Steps taken to respond to this data request:
|     | Step                                                                                 |
| --- | ------------------------------------------------------------------------------------ |
| 1   | Read in dphe144 CEDRS_view SQL table and create SAS dataset                          |
| 2   | Read in dphe66 tables using SQL join to get Delta variant cases. Create SAS dataset. |
| 3   | Make edits to B16172 dataset                                                         |
| 4   | Read in populations data|

#
                 
## SAS Programs in this folder:

| Program name    | Input dsn      | Output dsn       | Purpose                                  
| --------------- | -------------- | ---------------- | ---------------------------------------- 
| READ.CEDRS_view | SQL data table | COVID.CEDRS_view | Access SQL table and save as SAS dataset|
| Check.CEDRS_view| COVID.CEDRS_view| *N/A*|Conduct data quality checks|
| Fix.CEDRS_view|COVID.CEDRS_view|COVID.CEDRS_view_fix|Make edits to CEDRS_view dataset|
| Read.B6172|SQL tables from CEDRS66 zDSI schema: <ul><li>Profiles</li><li>Events</li></ul><ul><li>LabTests</li></ul> |B6172_read|Create SAS dataset of variant cases|
| Read.B6172|SQL tables (Profiles, Events, LabTests) from CEDRS66 zDSI schema |B6172_read|Create SAS dataset of variant cases|| READ.populations|dbo144.populations|COVID.County_Population|Create SAS dataset of county population data|
|Check.B6172|B6172_read OR B6172_fix|*N/A*|Conduct data quality checks|
|Fix.B6172|B6172_read|COVID.B6172_fix|Make edits to B6172.read dataset
| READ.COPHS| Hosp144.COPHS|COVID.COPHS|Create SAS dataset from COPHS hospital data|
| READ.populations|dbo144.populations|COVID.County_Population|County population data to merge with ...|

#
---
#
## View font sizes:
- # Size 1
- ## Size 2
- ### Size 3
- #### Size 4
- ##### Size 5
- ###### Size 6


