## Background 
This data request on waning immunity came from Rachel S. There is email discussion between her and Debashis Ghosh. The outcome variable is breakthrough cases.


**Population**:  Confirmed and probable cases in CEDRS for 12/14/20 through 9/23/21. **Independent variables**: Time since vaccination and also age, gender, vaccine recieved. **Data requested**: Build a logistic regression model on outcome (Breakthrough case) by time since vaccination. 

## Code
Rachel S. had a dataset on dphe144 server named `timesincevax_regression_data`. The SAS program [Access.TimeSinceVax.sas](./Access.TimeSinceVax.sas) was used to read and curate this data table and create the SAS dataset `TimeSinceVax`. The SAS program [RFI.LR_on_Time_Since_Vax.sas](./RFI.LR_on_Time_since_Vax.sas) builds the logistic regression model. The contents of this dataset can be found [here](./Proc%20Contents_TimeSinceVax.pdf).
#
Step 1: Variable reduction. Not needed in this case since variables pre-selected.

Step 2: Univariate analysis.  

**Result of univariate analysis of variables with discrete values:**

![UniVarAnaly](images/Univariate_analysis.png)
##
Step 3: Logit plots of continuous variables. Assumption is that there is a linear relationship between continuous (or ordinal) independent variables and the logit of the outcome variable. These plots check that assumption.

**Logit plot of Age:**
![Logit_plot_Age](images/Logit_plots_Age2.png)

**Logit plot of Follow-up Time:**
![Logit_plot_FollowUp](images/Logit_plots_Followup_Time2.png)

**Logit plot of Time since vaccination:**
![Logit_plot_TimeSinceVax](images/Logit_plots_Time_Since_Vax2.png)

Findings:
````diff
+/*----------------------------------------------------------------------+-----------------*
+| 1. Age_Group should be put on the CLASS statment since it is non-linear in logit
+|    So it will NOT be treated as an ordinal variable.
+| 2. Follow-up time is linear in logit so it goes in the model as a continuous variable.
+| 3. Time since vaccination is linear in logit so it goes in model as a continuous variable.
+| 4. Age is NOT linear in the logit; several transformations were tested.
+|    Age squared resulted in the lowest AIC.
+*---------------------------------------------------------------------------------------*/
````
##
Step 4: Univariate analysis.  



**Issues:**
* Need access to or input from a biostatistician. 

