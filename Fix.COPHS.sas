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

DATA COVID.COPHS_fix;  set COPHS_read;
/*   Region = put(County_of_Residence, $WestSlope. );*/

** 1) Remove duplicate record  **;
   if MR_Number = 'M1373870' and Facility_Name = 'West Pines Hospital' then delete;
   if MR_Number = 'M1535914' and Hosp_Admission='08NOV20'd and Facility_Name = 'West Pines Hospital' then delete;

** 2) Restrict County_of_Residence = 'GRAND' to only Colorado **;
   if upcase(County_of_Residence) = 'GRAND' and Zip_Code in ('84515', '84532', '84540') then delete;

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

run;


**  5. Contents of final SAS dataset  **;

   PROC contents data=COVID.COPHS_fix varnum; run;



*** 6.  Post-edit checks ***;
***----------------------***;

  PROC print data= COVID.COPHS_fix ;
      where  (. < Hosp_Admission < '01JAN20'd)  OR  (Hosp_Admission > '01DEC21'd) ;
      id MR_Number ;
      var Hosp_Admission Facility_Name First_Name Last_Name Gender DOB Positive_Test Date_Left_Facility City County_of_Residence  ;
      format Facility_Name $45. First_Name Last_Name  $12.  City $15. ;
      title2 'Extreme values of hospital admission dates from COPHS';
run;
