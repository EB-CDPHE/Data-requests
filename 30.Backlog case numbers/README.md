On Friday April 22 Eduardo asked me to check the backlog files that were provided to him. There were two files to compare which he had placed on the K: drive - (K:\CEDRS\CEDRS COVID Report Outputs with and without Backlog Exclusions - April 2022).
The two files were:
1. Report Novel Coronavirus Listing - Excluded Backlog Output - 4.27.2022.xlsx
2. Report Novel Coronavirus Listing - Original Stored Proc Output - 4.27.2022.xlsx

I copied these files to C:\Users\eabush\Documents\My SAS Files\Data. I opened the two files and save as:
1. Excluded_Backlog_Output.xlsx
2. Original_Stored_Output.xlsx

The first tab ("Parameters") is deleted and the second tab is renamed to "data".

The request is for a daily summary generated from each of these two files and shared back with Eduardo.

I use this [SAS program](./RFI.Backlog_check.sas) to generate the two datasets. This program documents the specific steps taken.

There is a section of code for each workbook. The last statements in each section creates a SAS dataset. After running code, I navigate to the SAS dataset in the Explorer window and right-click on the dataset to view as Excel file. Save Excel workbooks to [shared drive](https://drive.google.com/drive/folders/1p_QHyvxk-MoAj7-l3QG3rzWHEDfgheLF).

Easy-peasy.

