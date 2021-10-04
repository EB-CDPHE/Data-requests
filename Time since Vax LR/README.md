## Background 
This data request on waning immunity came from Rachel S. There is email discussion between her and Debashis Ghosh. The outcome variable is breakthrough cases.


**Population**:  Confirmed and probable cases in CEDRS for 12/14/20 through 9/23/21. **Independent variables**: Time since vaccination and also age, gender, vaccine recieved. **Data requested**: Build a logistic regression model on outcome (Breakthrough case) by time since vaccination. 

## Code
Rachel S. had a dataset on dphe144 server named `timesincevax_regression_data`. The SAS program [Access.TimeSinceVax.sas](./Access.TimeSinceVax.sas) was used to read and curate this data table and create the SAS dataset `TimeSinceVax`. The SAS program [RFI.LR_on_Time_Since_Vax.sas](./RFI.LR_on_Time_since_Vax.sas) builds the logistic regression model. The contents of this dataset can be found [here](./Proc%20Contents_TimeSinceVax.pdf).
#
####Step 1: Variable reduction. Not needed in this case since variables pre-selected by Rachel S.

####Step 2: Univariate analysis.

**Issues:**
* Need access to or input from a biostatistician. 

