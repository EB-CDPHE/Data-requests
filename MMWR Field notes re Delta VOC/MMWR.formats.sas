

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
         'Alive' = 'Not Died'
         'Unknown' = 'Not Died'
         other = 'Not Died'  ;

      value AgeFmt
         0-69 = '<70 years'
         70-105 = '70+ years' ;
      value Age5cat
         0-19 = '0-19 years'
         20-39 = '20-39 years'
         40-59 = '40-59 years'
         60-79 = ' 60-79 years'
         80-105 = '80-105 years' ;

      value $MesaFmt
      'MESA'='MESA'
       other='ROC' ;

      value HospFmt
      ., 0 =  0
       1 = 1 
         other=0;

      value wavefmt
         low - '13SEP20'd = 'pre-Wave'
         '14SEP20'd to '03JAN21'd = 'Wave 1'
         '04JAN21'd to '14MAR21'd = 'Wave 2'
         '05APR21'd to '30MAY21'd = 'Wave 3' ;

run;



