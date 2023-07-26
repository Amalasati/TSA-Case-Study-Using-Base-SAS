%let path=/home/asatiamal0/ECRB94/data;
%let outpath=/home/asatiamal0/ECRB94;
ods pdf file="&outpath/ClaimsReport.pdf" style=meadow pdftoc=1;
ods noproctitle;

libname tsa "&path";
options VALIDVARNAME=v7;

proc import datafile="&path/TSAClaims2002_2017.csv" dbms=csv 
		out=tsa.ClaimsImport replace;
	guessingrows=max;
run;

/*Explore Data*/
proc print data=tsa.ClaimsImport;
run;

proc contents data=tsa.ClaimsImport varnum;
run;

proc freq data=tsa.ClaimsImport;
	tables Claim_Site Disposition Claim_Type Date_Received Incident_Date / nocum 
		nopercent;
	format incident_date date_received year4.;
run;

proc print data=tsa.ClaimsImport;
	where date_received < incident_date;
	format date_received incident_date date9.;
run;

/*Remove dulicate rows  */
proc sort data=tsa.claimsimport out=tsa.Claims_NoDups noduprecs;
	by _all_;
run;

/*Sort the data by ascending Incident_Date. */
proc sort data=tsa.Claims_NoDups;
	by incident_Date;
run;

data tsa.claims_cleansed;
	set tsa.claims_nodups;
/*Clean the Claim_Site column  */
	if claim_site in ('-','') then claim_site = "Unknown";
/*Clean the Disposition column  */
	if Disposition in ('-',"") then Disposition = 'Unknown';
	else if Disposition = 'losed: Contractor Claim' then Disposition ='Closed:Contractor Claim';
	else if Disposition = 'Closed: Canceled' then Disposition = 'Closed:Canceled';
/*Clean the Claim_Type column  */
	if Claim_Type in ('-','') then claim_Type="Unknown";	
	else if Claim_Type = 'Passenger Property Loss/Personal Injur' then Claim_Type='Passenger Property Loss';
	else if Claim_Type = 'Passenger Property Loss/Personal Injury' then Claim_Type='Passenger Property Loss';
	else if Claim_Type = 'Property Damage/Personal Injury' then Claim_Type='Property Damage';
/*Convert all State vlaues to uppercase and all StateName values to proper case.  */
	State=upcase(state);
	StateName=propcase(StateName);
/* Create a new column to indicate date issues. */
	if (Incident_Date > Date_Received or
		Date_Received = . or
		Incident_Date = . or
		year(Incident_Date) < 2002 or
		year(Incident_Date) > 2017 or
		year(Date_Received) < 2002 or
		year(Date_Received) > 2017) then Date_Issues="Needs Review";
/* Add permanent labels and formats. */
	format Incident_Date Date_Received date9. Close_Amount Dollar20.2;
	label Airport_Code = "Airport Code"
		  Airport_Name = "Airport Name"
		  Claim_Number = "Claim Number"
		  Claim_Type = "Claim Type"
		  Close_Type = "Close Type"
		  Close_Amount = "Close Amount"
		  Date_Issues = "Date Issues"
		  Date_Received = "Date Received"
		  Incident_Date = "Incident Date"
		  Item_Category = "Item Category";
/*Drop County and City.*/
	drop county city;
run;

proc freq data=tsa.claims_cleansed order=freq;
	tables Claim_Site
		   Disposition
		   Claim_Type
		   Date_Issues / nopercent nocum;
run;
		  
/*OVERALL ANALYSIS*/

/*1. How many date issues are in the overall data?  */
ods  proclabel "Overall Date Issues";
title "Overall Date Issues in the Data";
proc freq data=tsa.claims_cleansed order=freq;
	tables Date_Issues /missingssing nopercent nocum;
run;
title;

/*2. How many claims per year of Incident_Date are in the overall data? Be sure to include a plot. */
ods  proclabel "Overall claim by year"
ods graphics on;
title "Overall Claims by Year";
proc freq data=tsa.claims_cleansed;
	table Incident_Date /nocum nopercent plots=freeplot;
	format Incident_Date year4.;
	where Date_Issues is null;
run;
title;

/* SPECIFIC STATE ANALYSIS */

/*3. Lastly, a user should be able to dynamically input a specific state value and answer the following. */
/*a. what are the frequency values for Claim_Type  for the selected state?*/
/*b. what are the frequency values for Claim_Site  for the selected state?*/
/*c. what are the frequency values for Disposition  for the selected state?*/

%let statename = Hawaii;
ods proclabel "&statename Claims Overview";
title "&statename Claim Type, Claim Sites and Disposition";
proc freq data=tsa.claims_cleansed order=freq;
	table Claim_Type Claim_Site Disposition /nocum nopercent;
	where StateName="&statename" and Date_Issues is null;
run;
title;

/*d. what is the mean, minimum, maximum, and sum of Close_amount for the selected state? Round to the nearesr integer.*/
ods proclabel "&statename Claims Amount Statistics";
title "Close_Amount Statistics for &statename";
proc means data=tsa.claims_cleansed mean min max sum maxdec=0;
	var Close_Amount;
	where StateName="&statename" and Date_Issues is null;
run;
title;

ods pdf close;



