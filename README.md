# Data-requests - Parent directory for data requests

## Background: 
This is the parent directory for data requests, or RFI's (Requests for Information). Below are the typical steps taken to respond to data requests. Further documentation of a RFI can be found in corresponding OneNote folder. The README file in each subsequent folder should describe for the RFI the
        1) **Population**:  Individuals defined by place, time, and personal attributes.
        2) **Outcomes**:  The actual data being requested
        3) **Groups**: How the data should be grouped and compared. 
For SQL tables previously used, a Access.*.sas program should be in this folder and can be used to read and curate the SQL data table of interest. Otherwise, start with the [SASTemplate](SAS code templates/Read.CEDRS_SQL_table.sas) for accessing new SQL data table.  confirmed and probable cases.

#
## Process for responding to data requests:
|Step          |Description                                        |
|--------------|---------------------------------------------------|
|1|Create a new folder for the RFI
|2|Access SQL data tables
| | a) For data tables previously used, run appropriate Access.* program from this directory|
| | b) For new data tables, open Access.TEMPLATE and write new program|
|3| Add new data checks to the Check.*.sas program|
|4| Run the Fix.*.sas program to obtain curated and cleaned SAS dataset to use for RFI program|
|5| Write RFI.*.sas program for obtaining requested data from the specified population


#             
## SAS Programs in this folder:

| Program name    | Input Dataset  | Output Dataset   | Purpose                                  
| --------------- | -------------- | ---------------- | ---------------------------------------| 
| Access.CEDRS_view | dbo144.CEDRS_view (SQL data table) | COVID.CEDRS_view | Access CEDRS_view table and adjust variable types and length and save as SAS dataset|
| Check.CEDRS_view| COVID.CEDRS_view|*N/A*|Conduct data quality checks|
| Fix.CEDRS_view|COVID.CEDRS_view; & zDSI_Events_fix|COVID.CEDRS_view_fix|Edit County and Age variables|
| Access.B6172|SQL tables (Profiles, Events, LabTests) from CEDRS66 zDSI schema |B6172_read|Create SAS dataset of variant cases|
|Check.B6172|B6172_read OR B6172_fix|*N/A*|Conduct data quality checks|
|Fix.B6172|B6172_read|COVID.B6172_fix|Make edits to B6172.read dataset|
| Access.COPHS| Hosp144.COPHS|COVID.COPHS|Create SAS dataset from COPHS hospital data|
|Check.COPHS|  |  |  |
|Fix.COPHS| | | |
| Access.populations|dbo144.populations|COVID.County_Population|Create SAS dataset of county population data|
|Access.zDSI_Events|dbo66.zDSI_Events|work.zDSI_Events_read|Access Profiles table and adjust variable types and length and save as SAS dataset.
|Fix.zDSI_Events|zDSI_Events_read|zDSI_Events_fix|Convert age for all age types to Age_in_Years

#
## Process chart for responding to data requests:

