/**********************************************************************************************
PROGRAM:  Fix.COPHS
AUTHOR:   Eric Bush
CREATED:	 July 19, 2021
MODIFIED: 	
PURPOSE:	 Explore created SAS dataset
INPUT:	       COPHS_read
OUTPUT:	 COVID.COPHS_fix
***********************************************************************************************/

/*----------------------------------------------------------------------*
 | Fixes made in this code:
 |    vv SAS dataset = COPHS_read  vv                 <-- READ dataset         
 | 1. Remove duplicate records
 | 2. Restrict County_of_Residence = 'GRAND' to only Colorado
 | 3. Hospital admission dates that appear wrong
 | 4. Fix bad zip codes
 | 5. Contents of final dataset
 |
 |    vv SAS dataset = COVID.COPHS_fix  vv            <-- FIX dataset         
 | 6. Post edit checks
 *----------------------------------------------------------------------*/

** Contents of the input SAS dataset that was created in the Access.* program and validated with the Check.* programn **;

Libname COVID 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Data\SAS Code\data'; run;

   PROC contents data=COPHS_read varnum; run;


***  Make edits to CEDRS_view_read and create COVID.CEDRS_view_fix  ***;
***-----------------------------------------------------------------***;


** STEP 1:  De-duplicate records with identical MR_Number, DOB, Hosp_Admission, Facility_Name and Date_Left_Facility **;
   proc sort data= COPHS_read  
              out= COPHS_DeDup_Admit  NODUPKEY ;  
      by MR_Number DOB  Hosp_Admission  Facility_Name  Date_Left_Facility ; 
run;
 

DATA COVID.COPHS_fix;  set COPHS_DeDup_Admit;
/*   Region = put(County_of_Residence, $WestSlope. );*/

** 1) Remove duplicate record  **;
   if MR_Number = 'M1373870' and Facility_Name = 'West Pines Hospital' then delete;
   if MR_Number = 'M1535914' and Hosp_Admission='08NOV20'd and Facility_Name = 'West Pines Hospital' then delete;

** 2) Restrict County_of_Residence = 'GRAND' to only Colorado **;
/*   if upcase(County_of_Residence) = 'GRAND' and Zip_Code in ('84515', '84532', '84540') then delete;*/

   ChkCounty = put(County_of_Residence, $CntyChk.);
   if CO=1  AND  ChkCounty='NON-COLO COUNTY NAME' then CO=9;

** Bad county name **;
   if County_of_Residence = 'LATIMER' then County_of_Residence = 'LARIMER';


   * TEMP FIX  - need to look up each record and see which of the tri-counties they are in *;
   if Facility_Name = 'Kindred Hospital Aurora' and County_of_Residence = 'AURORA' then County_of_Residence = 'ADAMS';
   if MR_Number='193309972' and County_of_Residence = 'COLORADO' then County_of_Residence = 'EL PASO';
   if MR_Number='CEUL2114858' and County_of_Residence = 'COLORADO' then County_of_Residence = 'LA PLATA';
   if MR_Number='194048470' and County_of_Residence = 'COLORADO' then County_of_Residence = 'WELD';
   if MR_Number='CEUL1450870' and County_of_Residence = 'COLORADO' then County_of_Residence = 'ADAMS';
   if MR_Number='213144178' and County_of_Residence = 'COLORADO' then County_of_Residence = 'ADAMS';
   if MR_Number='154771059' and County_of_Residence = ' ' then County_of_Residence = 'WELD';
   if MR_Number='1304921' and address_line_1 = 'FOREST STREET COMPASSION' then County_of_Residence = 'DENVER';


** 3) Edit Hospital admission dates  **;
   if Hosp_Admission = '01NOV2019'd then Hosp_Admission = '01NOV2020'd ;
   if Hosp_Admission = '22MAR1921'd then Hosp_Admission = '22MAR2021'd ;
   if Hosp_Admission = '28DEC2021'd then Hosp_Admission = '28DEC2020'd ;
   if Hosp_Admission = '27DEC2021'd then DO;
      Hosp_Admission = '27DEC2020'd ;
      Positive_Test  = '27DEC2020'd ;
      Date_Left_Facility = '30DEC2020'd ;
      END;
   if Hosp_Admission = '03JUL2018'd then Hosp_Admission = '01NOV2020'd ;

** 4) Fix bad zip codes  **;
   if Zip_Code in 
      ('7481', '1450', '8327', '7442', '2657', '1012', '7821', '3801', '3234', '8234'
       '7960', '7670', '2906', '7090', '6870', '1844') 
      then Zip_Code = cat('0', Zip_Code);
   if Zip_Code in ('962', '794') then Zip_Code = cat('00', Zip_Code);
   if Zip_Code in ('99999', 'UNKNO') then Zip_Code = '';

** 5) Fix bad merges  **;
 if Last_Name = 'Dutchie-Cooley' then Last_Name = 'Dutchie Cooley';

** 6) Fix values that are lower case  **;
   Discharge_Transfer_Death_Disposi = propcase(Discharge_Transfer_Death_Disposi);

** 7) Fix race and ethncity responses  **;
   if Race = "Other Race" then Race = "Other";
   if Race = "Native Hawaiian or Other Pacific Islan" then Race = "Pacific Islander/Native Hawaiian";
   if Ethnicity = "Declined to specify" then Ethnicity = "Unknown or Unreported";
   if Ethnicity = "Non-Hispanic or Latino" then Ethnicity = "Non Hispanic or Latino";

run;


**  5. Contents of final SAS dataset  **;

   PROC contents data=COVID.COPHS_fix varnum;  title1 'COVID.COPHS_fix'; run;



*** 6.  Post-edit checks ***;
***----------------------***;

/*  PROC print data= COVID.COPHS_fix ;*/
/*      where  (. < Hosp_Admission < '01JAN20'd)  OR  (Hosp_Admission > '01DEC21'd) ;*/
/*      id MR_Number ;*/
/*      var Hosp_Admission Facility_Name First_Name Last_Name Gender DOB Positive_Test Date_Left_Facility City County_of_Residence  ;*/
/*      format Facility_Name $45. First_Name Last_Name  $12.  City $15. ;*/
/*      title2 'Extreme values of hospital admission dates from COPHS';*/
/*run;*/


/*   PROC freq data= COVID.COPHS_fix ;*/
/*      tables  Race  Ethnicity ; */
/*run;*/
