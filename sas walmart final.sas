*MILESTONE 1 – Importing Data;
 
libname project "/home/u63044868/PROJECT";

PROC IMPORT out=PROJECT.walmart
			DATAFILE='/home/u63044868/PROJECT/Walmart.csv'
			DBMS=CSV REPLACE;
			GETNAMES=YES;
run;

*MILESTONE 2 – Data Cleaning;

data data_cleaning;
set project.walmart;
Store_Number = put(Store,2.);
drop Store;
Unemployment = Unemployment/100;
format Unemployment 8.4;
format date WEEKDATE.;
format weekly_sales dollar12.2;
format fuel_price dollar12.2;
format Unemployment PERCENTn.4;
format CPI 8.2;
rename Temperature = Temperature_in_Farrenheit;
run;
data cleaned;
retain store_number;
set data_cleaning;
run;
Title "Final Dataset";
proc print data=cleaned (obs=40);
run;
proc contents data = cleaned;
run;

proc means data = cleaned;
run;


*MILESTONE 3- EXPLORATORY ANALYSIS;

*PART 1. CREATE A NEW VARIABLE CALLED “YEAR” TO THE CLEANED DATASET BY USING THE YEAR FUNCTION;

Data cleaned_walmart;
Set cleaned;
Year=year(date);
run;

Title"Add a new variable 'year' to cleaned dataset";
Proc Print Data=cleaned_walmart (obs=5);
Run;

Proc Contents Data=cleaned_walmart;
run;

Proc Means Data=cleaned_walmart n nmiss mean median max min stddev maxdec=1;
run;

* PART 2. EXAMINE THE OVERALL SALES PERFORMANCE OVER YEARS;

Proc Means data=cleaned_walmart sum;
   var weekly_sales;
   class year;
run;

Proc sgplot data=cleaned_walmart;
title "Total Sales of walmart stores over three years";
vbar year /response= weekly_sales nofill barwidth=.25;
run;


*PART 3. WHO ARE THE TOP 5 STORES FOR EACH YEAR?;

*3.1 Sort the data set by year store, list the top 5 stores;

*3.2 Sorting the data by year and weekly_sales;
Proc sort data=cleaned_walmart;
by year descending weekly_sales;
run;

*3.3 Creating a rank variable for each year;
   data cleaned_walmart_ranked;
   set cleaned_walmart;
   by year;
   if first.year then rank=1;
   else rank+1;
run;

*3.4 Filtering the top 5 sales performance for each year and create a table for that;
proc sql;
   create table top5_walmart as
   select *
   from cleaned_walmart_ranked
   where rank <= 5
   order by year, rank;
quit;


proc print data=top5_walmart (keep=rank year store_number weekly_sales);
id rank year;
title"Top5 walmart stores from each year";
run;


*3.5 Creating a bar chart of top 5 Walmart stores by year;
proc sgplot data=top5_walmart;
   title 'Top 5 Walmart Stores by Year';
   vbar store_number / response=weekly_sales group=year groupdisplay=cluster
                 datalabel=rank;
   xaxis label="Top5 stores";
   yaxis label='Sales';
run;


*PART 4. GRAPHS AND CHARTS HELP TO EXPLORE THE OUTLIERS OF THE DATASET;

*4.1 Using proc mean to check the values of mean and median of each variable;

Proc Means Data=cleaned_walmart mean median max min stddev maxdec=1;
run;

*4.2 Based on the results, we want to check the normality of weekly_sales, temperate and CPI by creating histogram and Boxplot;

*4.2.1 Creating histogram and simple boxplot for the weekly_sales;
Title "Histogram of weekly_sales with a Normal Curve Overlaid";
Proc Sgplot Data=cleaned_walmart;
histogram weekly_sales/;
Density weekly_sales;
Run;

Title "Boxplot of weekly_sales";
Proc Sgplot data=cleaned_walmart;
hbox weekly_sales/ group=year;
run;

*4.2.2 Create histogram and simple boxplot for temperature_in_Farrenheit;
Title "Histogram of Temperature with a Normal Curve Overlaid";
Proc Sgplot Data=cleaned_walmart;
histogram temperature_in_Farrenheit;
Density temperature_in_Farrenheit;
Run;

Title "Boxplot of temperature";
Proc Sgplot data =cleaned_walmart;
vbox temperature_in_Farrenheit/group =year;
run;

*4.2.3 Create histogram and simple boxplot for CPI;
Title "Histogram of CPI with a Normal Curve Overlaid";
Proc Sgplot Data=cleaned_walmart;
histogram CPI;
Density CPI;
Run;

Title "Boxplot of CPI";
Proc Sgplot data =cleaned_walmart;
vbox CPI /group =year;
run;

* Some outliers have been identified based on the histograms and boxplots for the two variables. we need to impute or remove these outliers before carrying on further analysis;

libname project "~/PROJECT";

data data_cleaning;
set project.walmart;
Store_Number = put(Store,2.);
drop Store;
Unemployment = Unemployment/100;
format Unemployment 8.4;
format date WEEKDATE.;
format weekly_sales dollar12.2;
format fuel_price dollar12.2;
format Unemployment PERCENTn.4;
format CPI 8.2;
rename Temperature = Temperature_in_Farenheit;
run;

data Cleaned_Walmart;
retain store_number;
set data_cleaning;
run;

Title "Final Dataset";
proc print data=Cleaned_Walmart (obs=40);
run;

proc contents data = Cleaned_Walmart;
run;

* MILESTONE 4;

*PART 1: EXAMING THE NUMERIC VARIABLE;

Title 'Examining numeric variables in the data set';
PROC MEANS Data=Cleaned_Walmart n nmiss min max mode mean stddev maxdec=3;
VAR numeric;
RUN;

*PART 2: IDENTIFY THE RELATIONSHIP BETWEEN HOLIDAY WEEKS AND SALES;

Title 'Examine relationship between Holiday and sales';
proc ttest data=Cleaned_Walmart ;
  class holiday_flag;
  var weekly_sales;
run;

Title 'Sales in Holiday Week versus Sales in Non Holiday Week';
proc sgplot data=Cleaned_Walmart;
   vbar Holiday_Flag / response=Weekly_Sales stat=mean;
run;

*PART 3: IDENTITY WHICH HOLIDAY IMPACT THE MOST ON SALES;

proc sql;
  create table total_sales as
  select date, sum(weekly_sales) as total_sales
  from Cleaned_Walmart
  group by date;
quit;

proc print data=total_sales;
run;

proc sgplot data=total_sales;
  series x=date y=total_sales / curvelabel;
  xaxis valuesformat=date9. label='Date';
  yaxis label='Total Weekly Sales';
run;

*PART 4: WHAT FACTORS CAN IMPACT ON SALES OF A STORE?;

*4.1 Create a new dataset that contains only the values of the selected store;

proc sort data=Cleaned_Walmart;
  by store_number weekly_sales;
run;

proc summary data=Cleaned_Walmart;
  class store_number;
  var weekly_sales;
  output out=store_summary sum(weekly_sales)= ;
  format weekly_sales dollar24.2;
run;

data store_summary;
  set store_summary;
  if store_number > 0;
run;

proc sort data=store_summary;
  by descending weekly_sales;
run;

data store_data;
  set Cleaned_Walmart;
  where store_number = '20';
run;

Proc print data=store_data (obs=20);
run;

*4.2 Using the new data set to run a regression model to identify the relationship between variables;

proc reg data=store_data;
  model weekly_sales = Temperature_in_Farenheit fuel_price cpi unemployment ;
run;

Title 'Regression of Temperature';
proc sgplot data=store_data;
  scatter x=Temperature_in_Farenheit y=weekly_sales;
  reg x=Temperature_in_Farenheit y=weekly_sales / lineattrs=(color=red thickness=2);
run;
