


 PROC contents data= Cases_Vx  varnum ;
      title1 'import of COVID_Events sheet from Rachel S after she added Vx data ';
run;
title1;
 PROC contents data= MMWR_cases varnum ;   run;

DATA Vx_temp;  set Cases_Vx(rename=(first_vacc_date=tmp_first_vacc_date  EventID=tmp_EventID));
   EventID = cats(tmp_EventID);

   if UTD_On = 'NA' then UTD_On = '';
   if UTD_On = 'NA' then UTD_On = '';

  UTD_Date = input(UTD_On, yymmdd10.);   format UTD_On yymmdd10.;
  first_vacc_date = input(tmp_first_vacc_date, yymmdd10.);   format first_vacc_date yymmdd10.;

   Label
      UTD_Flag = 'Fully Vaccinated Y/N'
      UTD_Date = 'Date fully vaccinated' 
      Vax = 'Vaccination status' ;
   Drop tmp_: ;
run;

%shrink(Vx_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;

 PROC contents data= Vx_temp_ varnum ;   run;


   proc sort data=Vx_temp_ out=VxEvents ; by EventID;
   proc sort data=MMWR_cases out=CaseEvents ; by EventID;
DATA CEDRS_Vx ; set  ;
run;






** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;


 PROC contents data= MMWR_cases varnum ;   run;


PROC sort data= MMWR_cases(keep= ProfileID EventID Hospitalized  Reinfection  Breakthrough Outcome CollectionDate Age_Years)  
   out=MMWRkey; 
   by ProfileID EventID;












