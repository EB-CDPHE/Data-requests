

** CHAIN **;
title;
   proc print data= Specimens_read;  where EventID='1084005'; var EventID LabSpecimenID CollectionDate; title1 'Specimens_read'; run;
   proc print data= Lab_TT229_fix;   where EventID='1084005';  var EventID LabSpecimenID ResultDate_TT229; title1 'Lab_TT229_fix';   run;


   proc print data= Specimens_w_PCR;  where EventID='1251100'; var EventID LabSpecimenID CollectionDate ResultDate_TT229 ; title1 'Specimens_w_PCR';  run;


   proc print data= COVID.CEDRS_view_fix;  where EventID='1084005'; var EventID  CollectionDate ; title1 'COVID.CEDRS_view_fix';  run;

   proc print data= CEDRS_PCR1;  where EventID='1084005'; var EventID LabSpecimenID CollectionDate ResultDate_TT229 ; title1 'CEDRS_PCR1';  run;

   proc print data= CEDRS_PCR2;  where EventID='1084005'; var EventID LabSpecimenID CollectionDate ResultDate_TT229 ; title1 'CEDRS_PCR2';  run;


   proc print data= SwP3;  where EventID='1084005'; var EventID LabSpecimenID CollectionDate ResultDate_TT229 ; title1 'SwP3';  run;
   proc print data= SwP3;  where EventID='1251100'; var EventID LabSpecimenID CollectionDate ResultDate_TT229 ; title1 'SwP3';  run;




l.TestType='COVID-19 Variant Type' and l.ResultText <> 'Specimen unsatisfactory for evaluation'
yes!
zDSI_LabTests
