

*** FORMATS ***;
   PROC format;
      value $ genderfmt
         'Female' = 'Female'
         'Male' = 'Male'
         other = 'Other' ;

      value $ variant
         'B.1.1.7 - for surveillance only. Not diagnostic' = 'B.1.1.7'
         'B.1.617.2 - for surveillance only. Not diagnostic' = 'B.1.617.2' ;

      value $ Outcome_2cat
         'Patient died' = 'Died'
         other = 'Not Died';

      value wavefmt
         low - '13SEP20'd = 'pre-Wave'
         '14SEP20'd to '03JAN21'd = 'Wave 1'
         '04JAN21'd to '14MAR21'd = 'Wave 2'
         '05APR21'd to '30MAY21'd = 'Wave 3' ;

run;



