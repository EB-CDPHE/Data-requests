

*** FORMATS ***;
   PROC format;
      value $LPHAregion
         'SEDGWICK','PHILLIPS','YUMA','WASHINGTON'
         'LOGAN','WELD','MORGAN','LARIMER'                       = 'North East region'
         'KIT CARSON','CHEYENNE','LINCOLN','ELBERT'              = 'East Central region'
         'KIOWA','BENT','PROWERS','BACA','CROWLEY','OTERO'       = 'South East region'
         'LAS ANIMAS','PUEBLO','FREMONT','CUSTER','HUERFANO'     = 'South Central region'
         'COSTILLA','ALAMOSA','SAGUACHE','RIO GRANDE','CONEJOS'  = 'San Luis Valley'
         'DOLORES','MONTEZUM','LA PLATA','SAN JUAN','ARCHULETA'  = 'South West region'
         'MINERAL','HINSDALE','OURAY','SAN MIGUEL',
         'MONTROSE','DELTA','GUNNISON'                           = 'West Central Partnership'
         'MESA'                                                  = 'MESA'
         'GARFIELD','PITKIN','EAGLE','SUMMIT','GRAND'            = 'Central Mountain region'
         'RIO BLANCO','MOFFAT','ROUTT','JACKSON'                 = 'North West region'

         'CLEAR CREEK','JEFFERSON','BROOMFIELD','DENVER',
         'ADAMS','ARAPAHOE','DOUGLAS'                            = 'Metro counties' 
         'EL PASO','TELLER','PARK','CHAFFEE','LAKE'              = 'Central region'   ;

      value $PedRegion
         'CHEYENNE', 'ELBERT', 'YUMA', 'MORGAN', 'LINCOLN',
         'SEDGWICK', 'PHILLIPS', 'KIT CARSON', 'LOGAN', 'WASHINGTON' = 'North East counties'
         'DENVER','JEFFERSON','ADAMS','ARAPAHOE' = 'Metro counties' 
         'BOULDER' = 'Boulder'
         'BROOMFIELD' = 'Broomfield'
         'DOUGLAS' = 'Douglas'
         other = 'other counties' ;
run;


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

      value Age3cat
         0-17 = '0-17 years'
         18-64 = '18-64 years'
         65-109 = '65-109 years' ;

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



