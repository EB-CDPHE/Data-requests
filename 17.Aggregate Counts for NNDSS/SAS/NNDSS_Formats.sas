/**********************************************************************************************
PROGRAM:  NNDSS_Formats.sas
AUTHOR:   Eric Bush
CREATED:  October 15, 2021
MODIFIED:	
***********************************************************************************************/

   PROC format;
      value $ GenderFmt
         'Female' = 'Female'
         'Male' = 'Male'
         other = 'Other' ;

      value $ Outcome_2cat
         'Patient died' = 'Died'
         'Alive' = 'Not Died'
         'Unknown' = 'Not Died'
         other = 'Not Died'  ;

      value Age8cat
         0-<1 = '< 1 year'
         1-<5 = '1-4 years'
         5-<15 = '5-14 years'
         15-<25 = '15-24 years'
         25-<40 = '25-39 years'
         40-<65 = '40-64 years'
         65-high = '40-59 years'
         ., 121 = 'Unknown' ;

      value MMWR_Month
         1-4 = 'January'
         5-9 = 'February'
         10-13 = 'March'
         14-17 = 'April'
         18-22 = 'May'
         23-26 = 'June'
         27-30 = 'July'
         31-35 = 'August'
         36-39 = 'September'
         40-44 = 'October'
         45-48 = 'November'
         49-53 = 'December' ;

run;

