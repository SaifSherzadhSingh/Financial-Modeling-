/* upload the data*/

libname co2 xlsx "/home/u63313980/my_content/PROJECT/STAT305 PROJECT/CO2 Emissions Data.xlsx";

/*Vehicle_Class, Make, and Transmission are all categorical variables*/

Title "part 1";
proc freq data=co2.data ;
table Vehicle_Class Make Transmission;
run;

/*Engine Size, Cylinders, City/Highway/Combined Fuel Consumption are quantitative variables */

ODS graphics on;
proc univariate data=co2.data all mode;
var Engine_Size	Cylinders City_Fuel_Consumption	Highway_Fuel_Consumption Comb_Fuel_Consumption;
run;

title "part 2";

/*Test of Association between CO2_EMISSIONS and vehicle_class*/
proc freq data=CO2.data;
tables Vehicle_Class*CO2_Emissions /chisq nocol norow nopercent ;
run;

/*Test of Association between CO2_EMISSIONS and Transmission*/
proc freq data=CO2.data ;
tables Transmission*CO2_Emissions /chisq nocol norow nopercent ;
run;



title "PART 3";

/* MAKE is not a relevant variable,
variables to avoid multicollinearity we check the correlation of the fuel consumption varibles*/

 ods graphics on;
 proc corr data=co2.data pearson;
var City_Fuel_Consumption  Highway_Fuel_Consumption  Comb_Fuel_Consumption;
 run;
 

 ods graphics on;
proc sgscatter data=co2.data;
  matrix City_Fuel_Consumption  Highway_Fuel_Consumption  Comb_Fuel_Consumption; 
run;

/* from the above, we note that the fuel consumption  variables are highly correlated
we only include the combined fuel consumption for reasons specified in the report*/  

title "part 3 initial model";

ODS graphics on;
proc logistic data=co2.data plots=all plots(MAXPOINTS=NONE);
class  CO2_Emissions Transmission Vehicle_Class(ref="HATCHBACK")/ param=ref; /* Make of vehicle will not effect co2 emissions*/
model CO2_Emissions(event="High emissions") =
 Transmission Vehicle_Class Engine_Size	Cylinders Comb_Fuel_Consumption;
 run;
 
 title "part 4 and 5 reduced/final model";
 ODS graphics on;
proc logistic data=co2.data plots=all plots(MAXPOINTS=NONE);
class  CO2_Emissions Transmission Vehicle_Class(ref="HATCHBACK")/ param=ref; /* Make of vehicle will not effect co2 emissions*/
model CO2_Emissions(event="High emissions") =
 Vehicle_Class 	Cylinders Comb_Fuel_Consumption
 / aggregate=(Transmission Vehicle_Class Engine_Size Cylinders City_Fuel_Consumption	Highway_Fuel_Consumption Comb_Fuel_Consumption)
 lackfit scale=none; /* options for overdispersion and goodness of fit test*/ /*all  explanatory varibles considered for the overdispersion test*/
 run;
 /*importing the customer_shopping_data directly, via proc import, in a SAS folder called PROJECT, under "my_content". The project was done both via the SAS Enterprise Guide and SAS Studio. For convenience to group members, SAS studio is used below*/
/*  excel file csn be uploaded by using a libname statment*/

FILENAME REFFILE '/home/u63313980/my_content/PROJECT/Customer_Shopping_Data.csv';

PROC IMPORT DATAFILE=REFFILE
DBMS=CSV
OUT=WORK.PROJECTGROUP4;
GETNAMES=YES;
RUN;


/* Using proc contents to view the sampling population and variables of interest*/
PROC CONTENTS DATA=WORK.PROJECTGROUP4;
RUN;

/* Sorting the data by our variable of interest, and price,  to run the subsequent proc steps"*/

proc sort data=WORK.PROJECTGROUP4;
by price;
run;


/* SRS WTR*/

TITLE1 "SRS WTR for estimating the variable price"; /* the same variable will be estimated using all methods*/

/* We will use proc surveyselect to generate the sample for each of the 4 methods.*/
PROC SURVEYSELECT
DATA=WORK.PROJECTGROUP4
SAMPSIZE= 10000 /* As the sampling population is large, in order to attain accurate inferences and to minimize the variance, we choose a large sample size, relative to the total sampling population{the minimum sample size decided was 10% of the total sampling population, we used 10000} */
OUT= GP4_USING_SRS /* each method will have its own table*/
METHOD=SRS /* SRS WTR*/
SEED=202304
stats;
run;

/* Use proc surveymeans, to obtain all relevant summary statistics and a 99% CI, the same applies for all other methods*/
proc surveymeans
data= work.gp4_using_srs /* The results of each sampling method will be stored in its own table*/
alpha=0.01 /* for a 99% CI*/
total=99457 /* our N, or total sampling population*/
mean sum varsum cvsum clsum clm var deciles max min quartiles;
var price; /* the variable we are estimating */
weight SamplingWeight;
run;

/*SRS WR*/
/*Comments for SRS WR are the same for SRS WTR. We expect SRS WTR to give us a more accurate result (SRS WTR should have a smaller variance than SRS WR)*/

TITLE2 "SRS WR";


PROC SURVEYSELECT
DATA=WORK.PROJECTGROUP4
SAMPSIZE= 10000
OUT= WORK.GP4_USING_URS
OUTHITS 
METHOD=URS
SEED=202304
stats;
run;

proc surveymeans
data= WORK.GP4_USING_URS alpha=0.01
total=99457
mean sum varsum cvsum clsum  clm var deciles max min quartiles ;
var price;
weight SamplingWeight;
run;

/* STRATIFICATION */

TITLE3 "STRATIFICATION SAMPLE";

/* use proc sort, to sort our stratification variable, item category, in ascending order. We choose the category of item, as different items, such as books and technology, will have similar prices respectively. By grouping similar items into strata and performing SRS WTR, we can reduce overall variability. We expect the most accurate results from STRATIFICATION*/
proc sort
data=WORK.PROJECTGROUP4 
out= WORK.GP4STRATASET; /* our sorted data is stored in a table called "GP4STRATASET"*/
by category; /* sort by stratification variable*/
run;
 
 /* we run proc freq to get the %weights of each item category. We want our sample to best represent our sampling population. We apply the %weights of each category of the item on our sampling size of 10000 to get the sampsize)*/
proc freq
data= WORK.GP4STRATASET;
table category / out=WORK.GP4_STRATA_SIZES(rename=(count=_total_)); /*the table GP4_STRATA_SIZES will be used in proc surveymeans total statment*/
run;


proc surveyselect
data=WORK.GP4STRATASET
sampsize=(501 3467 1518 1486 1009 503 502 1014) /* based on the %s of category items of sample population using PROC FREQ; the sum of all stratum = 10000 {our n} */
out=WORK.GP4_USING_STRATA
method=srs /* we will use SRS WTR in each stratum, as it is more accurate than the SRS WR*/
seed=202304
stats;
strata category; /* stratification variable*/
run;

proc surveymeans
data= WORK.GP4_USING_STRATA
alpha=0.01
total= WORK.GP4_STRATA_SIZES
mean sum varsum cvsum clsum clm var deciles max min quartiles ;
var price;
strata category; /* out stratification variable is the category of item*/
weight SamplingWeight;
run;



/* CLUSTER*/

TITLE4 "CLUSTER SAMPLE";

/* We will divide our sampling population into groups based on the shopping mall. We expect that cluster sampling will give the least accurate estimates of the parameters*/
/* there is no need to use proc sort or proc freq with cluster sampling as the number of clusters can be viewed using Excel data analytics*/


proc surveyselect
data=WORK.PROJECTGROUP4
sampsize= 7 /* there are 10 clusters we have decided to choose 7. This is done to increase the accuracy, reduce sampling error and ensure fair representation. This will allow cluster estimates to be closer to the true parameters*/
out=WORK.GP4_USING_CLUSTER
method=srs /* We use SRS WTR to choose the 7 clusters*/
seed=202304
stats;
cluster shopping_mall; /* our cluster variable is shopping mall*/
run;

proc surveymeans
data= WORK.GP4_USING_CLUSTER
alpha=0.01
total=10 /* This is the total clusters, not sampling population total*/
mean sum varsum cvsum clsum clm var deciles max min quartiles ;
var price;
weight SamplingWeight;
cluster shopping_mall;
run;

Title5 "Proportions";

/* proportions are a special case of mean. We want to compare the proportions of males vs females, FROM THE AGE of 22-65{inclusive} who spend over the average price {using the cluster mean result as it was the most accurate--> lowest variance}*/

data MALEGP4PROPORTIONS; /* our data table to include the proportion values*/
set  WORK.PROJECTGROUP4; /* our existing table of sampling population*/
drop  category quantity shopping_mall invoice_date invoice_no customer_id payment_method; /* we want to make inferences on the proportions of males vs females who spend over the average price*/
if price>=690.33 and gender ="Male" and age >= 22 <= 65 then proportion=1;else proportion=0; /* if the observational unit is a male AND spends 690.33 or more and is between 22-65 inclusive, well asign a 1, otherwise a 0*/
run;

PROC SURVEYSELECT
DATA=MALEGP4PROPORTIONS
SAMPSIZE= 10000 /* As the sampling population is large, in order to attain accurate inferences and to minimize the variance, we choose a large sample size, relative to the total sampling population{the minimum sample size decided was 10% of the total sampling population, we used 10000} */
OUT= GP4_male_proportionss_USING_SRS /* each method will have its own table*/
METHOD=SRS /* SRS WTR*/
SEED=202304
stats;
run;

/* Use proc surveymeans, to obtain all relevant summary statistics and a 99% CI, the same applies for all other methods*/
proc surveymeans
data= GP4_male_proportionss_USING_SRS /* The results of each sampling method will be stored in its own table*/
alpha=0.01 /* for a 99% CI*/
total=99457 /* our N, or total sampling population*/
mean  clm ; /* we only want the mean , as proportion as a special case of the mean. The mean will therefore represent the proportion*/
var proportion; /* the variable we are estimating */
weight SamplingWeight;
run;

/* we will do the same for females, get the two results and compare*/

data FEMALEGP4PROPORTIONS; /* our data table to include the proportion values*/
set  WORK.PROJECTGROUP4; /* our existing table of sampling population*/
drop  age category quantity shopping_mall invoice_date invoice_no customer_id payment_method; /* we want to make inferences on the proportions of males vs females who spend over the average price*/
if price>=690.33 and gender ="Female" and age >= 22 <= 65 then proportion=1;else proportion=0; /* if the observational unit is a female  AND spends 690.33 or more and is between 22-65 inclusive, well asign a 1, otherwise a 0*/

PROC SURVEYSELECT
DATA= FEMALEGP4PROPORTIONS
SAMPSIZE= 10000 /* As the sampling population is large, in order to attain accurate inferences and to minimize the variance, we choose a large sample size, relative to the total sampling population{the minimum sample size decided was 10% of the total sampling population, we used 10000} */
OUT= Female_proportionss_USING_SRS /* each method will have its own table*/
METHOD=SRS /* SRS WTR*/
SEED=202304
stats;
run;

/* Use proc surveymeans, to obtain all relevant summary statistics and a 99% CI, the same applies for all other methods*/
proc surveymeans
data= Female_proportionss_USING_SRS/* The results of each sampling method will be stored in its own table*/
alpha=0.01 /* for a 99% CI*/
total=99457 /* our N, or total sampling population*/
mean  clm ; /* we only want the mean, as proportion is a special case of the mean. The mean will therefore represent the proportion*/
var proportion; /* the variable we are estimating */
weight SamplingWeight;
run;
 


 
