/**********************************************************************************************
PROGRAM: Read.COPHS_Preg
AUTHOR:  Eric Bush
CREATED: June 24, 2021
MODIFIED:	
PURPOSE:	Import COPHS dataset with additional varibles related to pregnancy.
INPUT:	Spreadsheet provided by Brian Erly: EXPANDED_FORMAT_COVID_Patient_Data_All_Hosp_2021-06-23
OUTPUT:	COVID.COPHS_Preg
***********************************************************************************************/


*** Code from Import data wizard (saved as "Import.COPHS_Preg.sas") ***;

PROC IMPORT OUT= WORK.COPHS_Preg 
            DATAFILE= "J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data\Pregnancy_data_062321.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="data$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

   PROC contents data= COPHS_Preg varnum ;  run;


*** Code to dress up imported dataset and save as permanant SAS dataset ***;
DATA COVID.COPHS_Preg ;  set COPHS_Preg ; 
   Rename
      Hospital_Admission_Date___MM_DD_    = Hosp_Admit_Date
      ICU_Admission_Date___MM_DD_YYYY_    = ICU_Admit_Date
      DOB__MM_DD_YYYY_                    = DOB
      Invasive_ventilator__Y_N_           = Invasive_Ventilator
      Died_in_ICU__Y_N_                   = Died_in_ICU
      Discharge_Transfer__Death_Date__    = Left_facility_date
      Discharge_Transfer_Death_Disposi    = Left_facility_reason
      Prior_To_Admission_Living_Circum    = Living_sit_b4_admit
      Pregnant_on_Admission__Y_N_         = Pregnant_at_Admit
      Gestational_Age_on_Admission__We    = Gest_week
      Estimated_Date_of_Delivery_on_Ad    = Est_Delivery_date
      Estimated_Date_of_Conception_on_    = Est_Conception_date
      Delivery_During_Admission__Y_N_     = Delivered_during_Admit
      Last_Day_in_ICU_During_Admission    = Left_ICU_date
      First_Day_on_Vent_During_Admissi    = Invasive_Ventilator_start
      Last_Day_on_Vent_During_Admissio    = Invasive_Ventilator_end
      First_Day_on_Dialysis_During_Adm    = Dialysis_start
      Last_Day_on_Dialysis_During_Admi    = Dialysis_end
      Principal_Visit_Diagnosis__ICD10    = ICD10_Primary_Dx   ;

run;


   PROC contents data=COVID.COPHS_Preg varnum ;  run;


























