


DATA COPHS_HiReAdmit; set COPHS_read(drop=Address_Line_1  Address_Line_2  filename  DateAdded);
      where MR_Number in ('1097954',  '1345065',   '1387869',  'CEUE01638818',  'CEUL2557164',  'H0452890',  'M000538741', 
                          'P0043691', 'S0134047',  'S0526208', 'S0540750', 'W00455941', 'W00519430', 'W00645967', '396653', 
                          'CEUE01337847', '2417438', 'W00703839', '20196926', 'W00120195', 'P0168646' );
run;
   proc sort data=COPHS_HiDup ; by MR_Number Hosp_Admission ;  run;
   PROC contents data=COPHS_HiDup varnum; run;
   PROC print data=COPHS_HiDup ; id MR_Number; run; 


DATA HiDup_fix; set COPHS_HiReAdmit ; by MR_Number Hosp_Admission ;
   array HospCVars{5} $ Facility_Name   Invasive_ventilator__Y_N_   Current_Level_of_Care   Died_in_ICU__Y_N_   Discharge_Transfer_Death_Disposi  ;
   array HospDates{5}   Hosp_Admission   ICU_Admission   Positive_Test   Date_left_facility   Last_Day_in_ICU  ;

   format Facility_Name1 Facility_Name2 $69.   Current_Level_of_Care1  Current_Level_of_Care2 $9.   Reason_Left1  Reason_Left2 $38. ;
   array HospFirst{5} $ Facility_Name1   Invasive_Ventilator1   Current_Level_of_Care1   Died_in_ICU1   Reason_Left1  ;
   array HospLast{5}  $ Facility_Name2   Invasive_Ventilator2   Current_Level_of_Care2   Died_in_ICU2   Reason_Left2  ;

   format Hosp_Admission1   ICU_Admission1   Positive_Test1   Date_left_facility1   Last_Day_in_ICU1  
          Hosp_Admission2   ICU_Admission2   Positive_Test2   Date_left_facility2   Last_Day_in_ICU2  mmddyy10.  ;
   array HospDate1{5}   Hosp_Admission1   ICU_Admission1   Positive_Test1   Date_left_facility1   Last_Day_in_ICU1  ;
   array HospDate2{5}   Hosp_Admission2   ICU_Admission2   Positive_Test2   Date_left_facility2   Last_Day_in_ICU2  ;

   retain ICU_eariest ICU_latest ;
   if first.MR_Number then do; ICU_eariest = .;  ICU_latest = .;  NumHospAdmits=0;  end;
      ICU_eariest = min(ICU_eariest, ICU_Admission);
      ICU_latest  = max(ICU_latest, ICU_Admission);
      NumHospAdmits+1;
   format ICU_eariest ICU_latest mmddyy10.   ;

   if first.MR_Number=1 and last.MR_Number=0 then DO;
      do h = 1 to 5; 
         HospFirst{h} = HospCVars{h} ; 
         HospDate1{h} = HospDates{h} ; 
      end;
    END;

   retain Facility_Name1   Invasive_Ventilator1   Current_Level_of_Care1   Died_in_ICU1   Reason_Left1 ;
   retain Hosp_Admission1   ICU_Admission1   Positive_Test1   Date_left_facility1   Last_Day_in_ICU1   ;
   retain Invasive_ventilator__Y_N_   Died_in_ICU__Y_N_   ICU_Admission   Last_Day_in_ICU  ;

   if last.MR_Number=1 then DO;
      do h = 1 to 5; 
         HospLast{h}  = HospCVars{h} ; 
         HospDate2{h} = HospDates{h} ; 
      end;
      output;
    END;

   DROP Facility_Name   Invasive_ventilator__Y_N_   Current_Level_of_Care   Died_in_ICU__Y_N_   Discharge_Transfer_Death_Disposi 
        Hosp_Admission   ICU_Admission   Positive_Test   Date_left_facility   Last_Day_in_ICU  ;

run;

   PROC print data=HiDup_fix; 
      id MR_Number;
      *by MR_Number;
        var DOB Gender Hosp_Admission1  Hosp_Admission2 NumHospAdmits Facility_Name1  Facility_Name2       
            ICU_eariest ICU_latest   Date_Left_Facility1  Date_Left_Facility2  Reason_Left1  Reason_Left2 ;
      format Reason_Left1 Reason_Left2 $20.  Facility_Name1 Facility_Name2 $40.  ;   
run;













   proc sort data= COPHS_read out=COPHS_sort; by MR_Number Last_Name First_Name Gender City Zip_Code County_of_Residence ;  * sort by patient level key variables;

** Macro definition **;
%macro Long2Wide(dsn, tdsn, byvar, tvar);
PROC transpose data=&dsn  out=&tdsn(drop= _NAME_)  prefix=&tvar; 
   by &byvar;  
   var &tvar;          
run;
%mend;


** Call macro  **;
%Long2Wide(COPHS_sort, COPHSvar1, MR_Number Last_Name First_Name Gender City Zip_Code County_of_Residence, Facility_Name)
%Long2Wide(COPHS_sort, COPHSvar2, MR_Number Last_Name First_Name Gender City Zip_Code County_of_Residence, Hosp_Admission)
%Long2Wide(COPHS_sort, COPHSvar3, MR_Number Last_Name First_Name Gender City Zip_Code County_of_Residence, ICU_Admission)
%Long2Wide(COPHS_sort, COPHSvar4, MR_Number Last_Name First_Name Gender City Zip_Code County_of_Residence, Invasive_ventilator__Y_N_)


** Merge datasets together  **;
Data COPHS_wide;  merge COPHSvar1-COPHSvar4;
   by MR_Number ;
run;

   PROC contents data=COPHS_wide varnum; run;

   proc print data= COPHS_wide; id MR_Number; run;















