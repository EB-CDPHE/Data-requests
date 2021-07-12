


 PROC contents data= Vx_Events  varnum ;
      title1 'import of COVID_Events sheet from Rachel S after she added Vx data ';
run;
title1;
 PROC contents data= MMWR_cases varnum ;   run;

DATA Vx_temp;  set Vx_Events(rename=(first_vacc_date=tmp_first_vacc_date  EventID=tmp_EventID));
   EventID = cats(tmp_EventID);

   if UTD_On ^= 'NA' then do;
      UTD_month = scan(UTD_On,1);
      UTD_day = scan(UTD_On,2);
      UTD_year = scan(UTD_On,3);
   end;
   UTD_Date = MDY(UTD_month, UTD_day, UTD_year);  format UTD_Date yymmdd10.;

   if tmp_first_vacc_date ^= 'NA' then do;
      FVD_month = scan(tmp_first_vacc_date,1);
      FVD_day = scan(tmp_first_vacc_date,2);
      FVD_year = scan(tmp_first_vacc_date,3);
   end;
   first_vacc_date = MDY(FVD_month, FVD_day, FVD_year);  format first_vacc_date yymmdd10.;

   Label
      UTD_Flag = 'Fully Vaccinated Y/N'
      UTD_Date = 'Date fully vaccinated' 
      Vax = 'Vaccination status' ;
   Drop tmp_: Age;
run;

** Shrink character variables in data set to shortest possible lenght (based on longest value) **;
%inc 'C:\Users\eabush\Documents\My SAS Files\Code\Macro.shrink.sas' ;

%shrink(Vx_temp)


** 6. Rename "shrunken" SAS dataset by removing underscore (at least) which was added by macro **;

 PROC contents data= Vx_temp_ varnum ;   run;
 PROC contents data= MMWR_cases varnum ;   run;


   proc sort data=Vx_temp_ out=VxEvents ; by EventID;
   proc sort data=MMWR_cases out=CaseEvents ; by EventID;
DATA MMWR_Vx ; merge VxEvents CaseEvents ;  by EventID;
run;

 PROC contents data= MMWR_Vx varnum ;   run;





** 5. Create libname for folder to store permanent SAS dataset (if desired) **;
Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;




PROC sort data= MMWR_cases(keep= ProfileID EventID Hospitalized  Reinfection  Breakthrough Outcome CollectionDate Age_Years)  
   out=MMWRkey; 
   by ProfileID EventID;



   PROC freq data= MMWR_Vx ;
      tables  County  Age_Years hospitalized;
      tables County  * Age_Years * hospitalized / nocol  ;
      format   County $MesaFmt.   Age_Years AgeFmt.  hospitalized HospFmt. ;
      title1 'Admission to hospital among cases';
      title2 'data= MMWR_cases';
run;



   PROC freq data= MMWR_Vx ;
      where County ^= 'MESA' and UTD_flag='1';
/*      tables  UTD_flag  Age_Years hospitalized;*/
      tables  Age_Years * hospitalized / nocol  ;
      format   County $MesaFmt.   Age_Years AgeFmt.  hospitalized HospFmt. ;
      title1 'Admission to hospital among cases';
      title2 'data= MMWR_Vx';
      title3 'NOT MESA county';
run;






