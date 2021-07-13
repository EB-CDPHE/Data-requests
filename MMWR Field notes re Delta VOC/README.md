# Data-requests

### This request is for estimates needed to complete table in the MMWR Field report manuscript.

## Steps taken to respond to this data request:
|     | Step                                                                                 |
| --- | ------------------------------------------------------------------------------------ |
| 1   | Read in dphe144 CEDRS_view SQL table and create SAS dataset                          |
| 2   | Read in dphe66 tables using SQL join to get Delta variant cases. Create SAS dataset. |
| 3   | Make edits to B16172 dataset                                                         |
| 4   | Read in populations data|



<!-- pagebreak -->
## **How do I insert an extra space between these paragraphs?**   
                        
                        

## SAS Programs in this folder:

| Program name    | Input dsn      | Output dsn       | Purpose                                  
| --------------- | -------------- | ---------------- | ---------------------------------------- 
| READ.CEDRS_view | SQL data table | COVID.CEDRS_view | Access SQL table and save as SAS dataset|
| Check.CEDRS_view| COVID.CEDRS_view| *N/A*|Code to conduct data quality checks|
| READ.populations|dbo144.populations|COVID.County_Population|Create SAS dataset of county population data|
| READ.COPHS| Hosp144.COPHS|COVID.COPHS|Create SAS dataset from COPHS hospital data|
| 

   
      










View font sizes:
### Size 3
## Size 2
# Size 1


