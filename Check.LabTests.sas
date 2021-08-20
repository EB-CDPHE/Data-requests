
   PROC freq data = LabTests_temp;
      where TestType = 'COVID-19 Variant Type' ;
      tables TestTypeID * TestType /list; 
run;





   PROC freq data = LabTests_read;
/*      tables CreateBYID * CreateBY /list; ** Name of person that created the teset result record;*/
/*      tables CreateDate ;*/
/*      tables CreateBYID * CreatedBYID /list ;*/  ** CreateDbyID only has 1200 responses, most are missing. DO NOT USE;
/*      tables CreateBYID * CreatedBYID * CreateBY/list ;*/
   tables ELRid  LabID LabSpecimenID LegacyTestID;
run;



