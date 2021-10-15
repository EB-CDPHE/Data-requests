/**********************************************************************************************
PROGRAM:  NNDSS_Formats.sas
AUTHOR:   Eric Bush
CREATED:  October 15, 2021
MODIFIED:	
***********************************************************************************************/

   PROC format;
      value $ genderfmt
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
         1-<5 = '20-39 years'
         5-<15 = '40-59 years'
         15-<25 = '40-59 years'
         25-<40 = '40-59 years'
         40-<45 = '40-59 years'
         45-<55 = '40-59 years'
         55-<65 = '40-59 years' ;
run;

