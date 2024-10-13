-- NAME : ROSHAN CHAWLA
-- BATCH : MAY 2024
-- Project : BANK CRM PROJECT 

use bankcrm_db;
select * from customerinfo;
select * from bank_churn;
select * from activecustomer;
select * from creditcard;
select * from exitcustomer;
select * from gender;
select * from geography;
-- ============================================================================================================================= --
-- SQL QUERY FOR CREATING RELATIONSHIP THROUGH PRIMARY KEY AND FOREIGN KEY------------------------------------------------------

-- Establishing connecting between customeinfo and bank_churn on CustomerID
Alter table customerinfo modify CustomerID INT Primary Key;
Alter table bank_churn add constraint foreign key(CustomerID) references customerinfo(CustomerID);
desc customerinfo;
desc bank_churn;

-- Establishing connecting between geography and customerinfo on GeographyID
Alter table geography modify GeographyID INT Primary Key;
Alter table customerinfo add constraint foreign key(GeographyID) references geography(GeographyID);
desc customerinfo;
desc geography;

-- Establishing connecting between gender and customerinfo on GenderID
Alter table gender modify GenderID INT Primary Key;
Alter table customerinfo add constraint foreign key(GenderID) references gender(GenderID);
desc customerinfo;
desc gender;

-- Establishing connecting between creditcard and bank_churn on CreditID
Alter table creditcard modify CreditID INT Primary Key;
Alter table bank_churn add constraint foreign key(CreditID) references creditcard(CreditID);
desc bank_churn;
desc creditcard;

-- Establishing connecting between exitcustomer and bank_churn on ExitID
Alter table exitcustomer modify ExitID INT Primary Key;
Alter table bank_churn add constraint foreign key(ExitID) references exitcustomer(ExitID);
desc bank_churn;
desc exitcustomer;

-- Establishing connecting between activecustomer and bank_churn on ActiveID
Alter table activecustomer modify ActiveID INT Primary Key;
Alter table bank_churn add constraint foreign key(ActiveID) references activecustomer(ActiveID);
desc bank_churn;
desc activecustomer;

-- ============================================================================================================================= --

-- OBJECTIVE QUESTION 1 : What is the distribution of account balances across different regions? -------------------------------
Select
	g.GeographyLocation as Region,
    Round(Count(bc.Balance),2) as NumberOfCustomers,
    Round(SUM(bc.Balance),2) as TotalBalance,
    Round(AVG(bc.Balance),2) as AverageBalance
From 	
	bank_churn bc 
Inner Join 
	customerinfo c on c.CustomerId = bc.CustomerId
Inner Join 
	geography g on c.GeographyID = g.GeographyID
Group By
	g.GeographyLocation
Order By
	TotalBalance DESC;

-- OBJECTIVE QUESTION 2 : Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. -------------------------------
With RankedSalaries as (
	select
		CustomerId,
		Surname,
		EstimatedSalary,
		BankDOJ,
		DENSE_RANK() OVER (Order by EstimatedSalary DESC) as SalaryRank
	From 
		customerinfo 
	where
		month(BankDOJ) IN (1,2,3)) #Assumed Last Quarter to be January, February and March as per Banking standard.
Select
	CustomerId,
    Surname,
    EstimatedSalary,
    BankDOJ,
    SalaryRank
From	
	RankedSalaries
Where
	SalaryRank <= 5
Order by
	SalaryRank;

-- OBJECTIVE QUESTION 3 : Calculate the average number of products used by customers who have a credit card.-------------------------------

Select
    Round(Avg(NumOfProducts),2) AS AverageNumberOfProducts
From 
    bank_churn
Where 
    CreditID = 1;
    
-- OBJECTIVE QUESTION 4 : Determine the churn rate by gender for the most recent year in the dataset-------------------------------
WITH RecentYearData AS (
    SELECT 
        MAX(YEAR(BankDOJ)) AS MostRecentYear
    FROM 
        customerinfo
),
GenderChurn AS (
    SELECT 
        g.GenderCategory AS Gender,
        COUNT(CASE WHEN b.ExitID = 1 THEN 1 END) AS ChurnedCustomers,
        COUNT(*) AS TotalCustomers
    FROM 
        bank_churn b
    JOIN 
        customerinfo c ON b.CustomerID = c.CustomerID
    JOIN 
        gender g ON c.GenderID = g.GenderID
    JOIN 
        RecentYearData r ON YEAR(c.BankDOJ) = r.MostRecentYear
    GROUP BY 
        g.GenderCategory
)
SELECT 
    Gender,
    ChurnedCustomers,
    TotalCustomers,
    (ChurnedCustomers / TotalCustomers) * 100 AS ChurnRate
FROM 
    GenderChurn;

-- OBJECTIVE QUESTION 5 : Compare the average credit score of customers who have exited and those who remain.   -------------------------------
select * from bank_churn;
select * from exitcustomer;

Select
	e.ExitID,
    Case
		When e.ExitID = 0 Then 'Retained'
		Else 'Exited'
	End as LoyaltyStatus,
    Round(Avg(b.CreditScore),0) as AvgCreditScore
From	
	exitcustomer e
Left Join 
	bank_churn b on e.ExitID = b.ExitID
Group By
	e.ExitID;
    
-- OBJECTIVE QUESTION 6 : Which gender has a higher average estimated salary, and how does it relate to the number of active accounts?    -------------------------------
select * from customerinfo;
select * from activecustomer;
select * from gender;

with RankedSalaries as (
	Select
		g.GenderID as GenderID,
        g.Gendercategory as Gendercategory,
        Round(Avg(c.EstimatedSalary),0) as AvgEstimatedSalary,
        Count(b.ActiveID) as CountOfActiveID,
        Rank() OVER (Partition by g.GenderID, g.Gendercategory order by Avg(c.EstimatedSalary) desc) as SalaryRank
	from 
		gender g 
	inner join
		customerinfo c on c.GenderID = g.GenderID
	inner join 
		bank_churn b on b.CustomerID = c.CustomerID
	Inner join
		activecustomer a on a.ActiveID = b.ActiveID
	Group by
		g.GenderID, g.Gendercategory
	)
Select
	Gendercategory,
    AvgEstimatedSalary,
    CountOfActiveID
from
	RankedSalaries
where 
	SalaryRank = 1
order by 
	AvgEstimatedSalary desc;

-- OBJECTIVE QUESTION 7 : Segment the customers based on their credit score and identify the segment with the highest exit rate. -------------------------------
select * from bank_churn;
select * from exitcustomer;

Select 
	Case
		When CreditScore between 800 and 850 then 'Excellent'
        When CreditScore between 740 and 799 then 'Very Good'
        When CreditScore between 670 and 739 then 'Good'
        When CreditScore between 580 and 669 then 'Fair'
        When CreditScore between 300 and 579 then 'Poor'
	End as CreditScoreSegment,
    Count(*) as TotalCustomers,
    Sum(Case When ExitID = 1 Then 1 Else 0 End) as ExitedCustomers,
    Round((Sum(Case When ExitID = 1 Then 1 Else 0 End) * 1.0 / Count(*)) * 100, 2) as ExitRate
From 
	bank_churn
Group by
	CreditScoreSegment
Order by 
	ExitRate Desc;

-- OBJECTIVE QUESTION 8 : Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.  -------------------------------
select * from customerinfo;
Select * from bank_churn;
select * from geography;

Select 
	g.GeographyLocation,
    count(b.ActiveID) as NoOfActiveCustomers
From 
	geography g
    inner join customerinfo c on c.GeographyID = g.GeographyID
    inner join bank_churn b on b.CustomerID = c.CustomerID
Where 
	b.ActiveID = 1 and b.Tenure > 5
Group By
	g.GeographyLocation;

-- OBJECTIVE QUESTION 9 : What is the impact of having a credit card on customer churn, based on the available data?  -------------------------------   
Select * from bank_churn;
	
Select 
	Case
		When CreditID = 1 Then 'Credit Card Holder'
        Else 'No Credit Card'
	End as CreditCardStatus,
    Count(*) as TotalCustomers,
    Sum(Case when ExitID = 1 Then 1 Else 0 End) as ExitedCustomers,
    Round((sum(Case when ExitID = 1 Then 1 Else 0 End) * 1.0 / Count(*)) * 100 , 2) as ChurnRate
From 
	bank_churn
Group by 
	CreditCardStatus;
    
-- OBJECTIVE QUESTION 10 : For customers who have exited, what is the most common number of products they have used?  -------------------------------   
select * from bank_churn;

Select 
	NumOfProducts,
    Count(CustomerID) as TotalCustomers
From 
	bank_churn
Where 
	ExitID = 1
Group by 
	NumOfProducts
Order by 
	TotalCustomers desc;
    
-- OBJECTIVE QUESTION 11 : Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). 
-- Prepare the data through SQL and then visualize it.  -------------------------------   

SELECT
	YEAR(BankDOJ) AS Year, 
	COUNT(*) AS NewCustomers
FROM
	customerinfo
GROUP BY
	YEAR(BankDOJ)
ORDER BY
	Year;

-- OBJECTIVE QUESTION 12 : Analyze the relationship between the number of products and the account balance for customers who have exited  -------------------------------  
select * from bank_churn;
Select * from exitcustomer;

Select 
	NumOfProducts,
	Count(CustomerID) as TotalCustomer,
    Round(Sum(Balance),2) as TotalBalance
From 
	bank_churn
Where 
	ExitID = 1
Group by 
	NumOfProducts
Order by 
	TotalBalance desc;
    
-- OBJECTIVE QUESTION 13 : Identify any potential outliers in terms of balance among customers who have remained with the bank.  -------------------------------  

-- Answered in Word File.

-- OBJECTIVE QUESTION 14 : How many different tables are given in the dataset, out of these tables which table only consists of categorical variables?  --------------------

-- The dataset consists of 7 tables. Out of these, the following 5 tables contain only categorical variables:

-- 1.	activecustomer
-- o	ActiveID (INT)
-- o	ActiveCategory (TEXT)

-- 2.	creditcard
-- o	CreditID (INT)
-- o	Category (TEXT)

-- 3.	exitcustomer
-- o	ExitID (INT)
-- o	ExitCategory (TEXT)

-- 4.	gender
-- o	GenderID (INT)
-- o	GenderCategory (TEXT)

-- 5.	geography
-- o	GeographyID (INT)
-- o	GeographyLocation (TEXT)

-- OBJECTIVE QUESTION 15 : Write a query to find out the gender-wise average income of males and females in each geography id. 
-- Also, rank the gender according to the average value. --------------------
select * from customerinfo;
select * from Gender;
select * from Geography;

With cte1 as (
	Select 
		geo.GeographyLocation,
		g.GenderCategory,
		Round(Avg(c.EstimatedSalary),2) as AverageIncome
	from 
		customerinfo c 
		inner join Gender g on c.GenderID = g.GenderID
		inner join Geography geo on c.GeographyID  = geo.GeographyID
	Group by 
		geo.GeographyLocation,
		g.GenderCategory
)
Select 
	GeographyLocation,
    GenderCategory,
    AverageIncome,
    dense_rank() over (Partition by GenderCategory order by AverageIncome desc) as GenderRank
From 
	cte1
Order by 
	AverageIncome desc;
    
-- OBJECTIVE QUESTION 16 : Write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+). ---------------------------  
select * from bank_churn;
select * from customerinfo;
select * from exitcustomer;

Select 
	Case 
		When c.Age between 18 and 30 Then '18-30'
        When c.AGe between 31 and 50 Then '30-50'
        When c.Age > 50 Then '50+'
	End as AgeBracket,
    Round(Avg(b.Tenure),2) as AvgTenure
From 
	customerinfo c 
    Inner join bank_churn b on c.CustomerID = b.CustomerID
Where
	ExitID = 1
Group by
	AgeBracket
Order by 
	AgeBracket;
    
-- OBJECTIVE QUESTION 17 : Is there any direct correlation between salary and the balance of the customers? 
-- And is it different for people who have exited or not?. --------------------------- 
select * from customerinfo;
select * from bank_churn;
select * from exitcustomer;
-- --(i) Salary and Balances of customer who have exited -- --
Select 
	c.CustomerID,
    c.Surname as CustomerName,
    c.EstimatedSalary as CustomerSalary,
    b.Balance as CustomerAccountBalance,
    e.ExitCategory
From
	customerinfo c 
    inner join bank_churn b on b.CustomerID = c.CustomerID
    inner join exitcustomer e on e.ExitID = b.ExitID
Where
	b.ExitID = 1
Order by 
	CustomerAccountBalance desc;
	
-- --(ii) Salary and Balances of customer who are retained -- --    

Select 
	c.CustomerID,
    c.Surname as CustomerName,
    c.EstimatedSalary as CustomerSalary,
    b.Balance as CustomerAccountBalance,
    e.ExitCategory
From
	customerinfo c 
    inner join bank_churn b on b.CustomerID = c.CustomerID
    inner join exitcustomer e on e.ExitID = b.ExitID
Where
	b.ExitID = 0
Order by 
	CustomerAccountBalance desc;
    
-- OBJECTIVE QUESTION 18 : Is there any correlation between the salary and the Credit score of customers? ---------------------------      
select * from customerinfo;
select * from bank_churn;

Select 
	c.CustomerID,
    c.Surname as CustomerName,
    c.EstimatedSalary as CustomerSalary,
    b.CreditScore,
    b.CreditID
From 
	customerinfo c 
    inner join bank_churn b on b.CustomerID = c.CustomerID;

-- OBJECTIVE QUESTION 19 : Rank each bucket of credit score as per the number of customers who have churned the bank. ---------------------------      
select * from bank_churn;

With CreditScoreBuckets as (
	Select 
		Case
			When b.CreditScore between 800 and 850 then 'Excellent'
			When b.CreditScore between 740 and 799 then 'Very Good'
			When b.CreditScore between 670 and 739 then 'Good'
			When b.CreditScore between 580 and 669 then 'Fair'
			When b.CreditScore between 300 and 579 then 'Poor'
		End as CreditScoreBucket,
		Count(b.CustomerID) as ChurnedCustomers
	From 
		bank_churn b 
	Where 
		b.ExitID = 0
	Group By 
		CreditScoreBucket
)
Select 
	CreditScoreBucket,
    ChurnedCustomers,
    Dense_Rank() Over (Order by ChurnedCustomers Desc) as ChurnRank
From
	CreditScoreBuckets
Order By 
	ChurnedCustomers desc;
    
-- OBJECTIVE QUESTION 20 : According to the age buckets find the number of customers who have a credit card. 
-- Also retrieve those buckets that have lesser than average number of credit cards per bucket. --------------------------- 
select * from customerinfo;
select * from bank_churn;

-- (i) Number of customers who have a credit card per each Age Bucket --
Select 
        Case 
            When c.Age Between 18 And 30 Then '18-30'
            When c.Age Between 31 And 50 Then '31-50'
            Else '50+'
        End As AgeBucket,
        Count(cc.CreditID) AS CreditCardCustomers
From 
	customerinfo c
	Left Join bank_churn b ON c.CustomerID = b.CustomerID
	Left Join creditcard cc ON b.CreditID = cc.CreditID   
	Left Join activecustomer a ON b.ActiveID = a.ActiveID
	Left Join exitcustomer e ON b.ExitID = e.ExitID
	Left Join gender g ON c.GenderID = g.GenderID
	Left Join geography geo ON c.GeographyID = geo.GeographyID
Where
	cc.CreditID = 1
Group By
	AgeBucket
Order By
	AgeBucket;

-- (ii) Age buckets that have lesser than average number of credit cards per bucket.
With AgeBuckets As (
	Select 
		Case 
			When c.Age Between 18 And 30 Then '18-30'
			When c.Age Between 31 And 50 Then '31-50'
			Else '50+'
		End As AgeBucket,
		Count(cc.CreditID) AS CreditCardCustomers
	From 
		customerinfo c
		Left Join bank_churn b ON c.CustomerID = b.CustomerID
		Left Join creditcard cc ON b.CreditID = cc.CreditID   
		Left Join activecustomer a ON b.ActiveID = a.ActiveID
		Left Join exitcustomer e ON b.ExitID = e.ExitID
		Left Join gender g ON c.GenderID = g.GenderID
		Left Join geography geo ON c.GeographyID = geo.GeographyID
	Where
		cc.CreditID = 1
	Group By
		AgeBucket
	Order By
		AgeBucket
),

AvgCreditCards As (
    Select 
		Avg(CreditCardCustomers) As AvgCreditCardsPerBucket
    From 
		AgeBuckets
)
Select 
    ab.AgeBucket, 
    ab.CreditCardCustomers
From
	AgeBuckets ab
	Cross Join AvgCreditCards avg_cc
Where
	ab.CreditCardCustomers < avg_cc.AvgCreditCardsPerBucket
Order By
	ab.CreditCardCustomers Asc;

-- OBJECTIVE QUESTION 21 : Rank the Locations as per the number of people who have churned the bank and average balance of the customers. ---------------------------      
With LocationChurnData As (
	Select 
		geo.GeographyID,
		geo.GeographyLocation,
		Count(b.CustomerID) As ChurnedCustomers,
		Round(Avg(b.Balance),2) As AvgBalance
	From 
		bank_churn b 
		Join customerinfo c on c.CustomerID = b.CustomerID
		Join geography geo on geo.GeographyID = c.GeographyID
	Where
		ExitID = 1
	Group By 
		geo.GeographyID,
		geo.GeographyLocation
)
Select
	GeographyID,
    GeographyLocation,
    ChurnedCustomers,
    Dense_Rank() Over (Order By ChurnedCustomers) as ChurnRank,
    AvgBalance,
    Dense_Rank() Over (Order by AvgBalance Desc) as BalanceRank
From 
	LocationChurnData
Order By 
	ChurnedCustomers Desc, AvgBalance Desc;
    
-- OBJECTIVE QUESTION 22 : As we can see that the “CustomerInfo” table has the CustomerID and Surname, 
-- now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, 
-- come up with a column where the format is “CustomerID_Surname”. ---------------------------   
	
Select 
    CustomerID, 
    Surname,
    Concat(CustomerID, '_', Surname) As CustomerID_Surname
From
	customerinfo;

-- OBJECTIVE QUESTION 23 : Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL. ---------------------------   
select * from bank_churn;

Select 
	b.CustomerID,
    b.CreditScore,
    b.Balance,
    b.ExitID,
    (Select e.ExitCategory
	From exitcustomer e 
    Where e.ExitID = b.ExitID) as ExitCategory
From 
	bank_churn b
Order By 
	b.Balance desc;
        
-- OBJECTIVE QUESTION 24 : Were there any missing values in the data, using which tool did you replace them and what are the ways to handle them? ------------------   

-- (i) Checking if bank_churn table has null values
SELECT 
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Missing_CustomerID,
    SUM(CASE WHEN CreditScore IS NULL THEN 1 ELSE 0 END) AS Missing_CreditScore,
    SUM(CASE WHEN Tenure IS NULL THEN 1 ELSE 0 END) AS Missing_Tenure,
    SUM(CASE WHEN Balance IS NULL THEN 1 ELSE 0 END) AS Missing_Balance,
    SUM(CASE WHEN NumOfProducts IS NULL THEN 1 ELSE 0 END) AS Missing_NumOfProducts,
    SUM(CASE WHEN CreditID IS NULL THEN 1 ELSE 0 END) AS Missing_CreditID,
    SUM(CASE WHEN ActiveID IS NULL THEN 1 ELSE 0 END) AS Missing_ActiveID,
    SUM(CASE WHEN ExitID IS NULL THEN 1 ELSE 0 END) AS Missing_ExitID
FROM 
    bank_churn;

-- (ii) Checking if customerinfo table has null values

SELECT 
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Missing_CustomerID,
    SUM(CASE WHEN Surname IS NULL THEN 1 ELSE 0 END) AS Missing_Surname,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Missing_Age,
    SUM(CASE WHEN GenderID IS NULL THEN 1 ELSE 0 END) AS Missing_GenderID,
    SUM(CASE WHEN EstimatedSalary IS NULL THEN 1 ELSE 0 END) AS Missing_EstimatedSalary,
    SUM(CASE WHEN GeographyID IS NULL THEN 1 ELSE 0 END) AS Missing_GeographyID,
    SUM(CASE WHEN BankDOJ IS NULL THEN 1 ELSE 0 END) AS Missing_BankDOJ
FROM 
    customerinfo;

-- OBJECTIVE QUESTION 25 : Write the query to get the customer IDs, their last name, 
-- and whether they are active or not for the customers whose surname ends with “on”. ------------------  
select * from customerinfo;

Select 
	c.CustomerID,
    c.Surname as LastName,
    a.ActiveCategory
From 
	customerinfo c
    inner join bank_churn b on c.CustomerID = b.CustomerID
    inner join activecustomer a on a.ActiveID = b.ActiveID
Where
	c.Surname like '%on'
Order By 
	c.Surname;
    
-- OBJECTIVE QUESTION 26 : Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns. 
-- One more point to consider is that the data in the Exited Column is absolutely correct and accurate. ------------------   

select * from bank_churn
where ActiveID = 0 and ExitID = 0;

-- =============================================================================================================================== -- 
-- =============================================================================================================================== -- 
-- =============================================================================================================================== -- 
-- =============================================================================================================================== -- 

-- SUBJECTIVE QUESTION 1 : What patterns can be observed in the spending habits of long-term customers compared to new customers, 
-- and what might these patterns suggest about customer loyalty? --------------------------------------------
SELECT 
    CASE 
        WHEN b.Tenure > 3 THEN 'Long-Term'
        ELSE 'New'
    END AS CustomerType,
    Round(AVG(b.Balance),2) AS AvgBalance,
    COUNT(b.CustomerID) AS NumberOfCustomers,
    Round(AVG(b.NumOfProducts),2) AS AvgProducts,
    Round(AVG(b.CreditScore),2) AS AvgCreditScore
FROM 
    bank_churn b
GROUP BY 
    CustomerType
ORDER BY 
    CustomerType DESC;
    
-- SUBJECTIVE QUESTION 2 : Which bank products or services are most commonly used together, and how might this influence cross-selling strategies? ---------------------
    
WITH ProductUsage AS (
	SELECT 
		CustomerID, 
        NumOfProducts,
		CASE 
			WHEN NumOfProducts = 1 THEN 'SavingsAccount'
			WHEN NumOfProducts = 2 THEN 'SavingsAccount, CreditCard'
			WHEN NumOfProducts = 3 THEN 'SavingsAccount, CreditCard, Loan'
			WHEN NumOfProducts >= 4 THEN 'SavingsAccount, CreditCard, Loan, InvestmentAccount'
		END AS ProductCombination
	FROM bank_churn
),
CombinationAnalysis AS (
	SELECT 
		ProductCombination, 
		COUNT(CustomerID) AS CustomerCount
	FROM 
		ProductUsage
	GROUP BY 
		ProductCombination
)
SELECT 
	CustomerCount,
    ProductCombination,
    ROUND(CustomerCount/(SELECT COUNT(*) FROM bank_churn) * 100, 2) AS PercentageOfCustomers
FROM
	CombinationAnalysis;
    
-- SUBJECTIVE QUESTION 3 : How do economic indicators in different geographic regions correlate with the number of active accounts and customer churn rates? ----------------

SELECT 
    geo.GeographyLocation,
    COUNT(b.ExitID) AS ChurnedCustomers,
    (COUNT(DISTINCT b.ExitID) / COUNT(DISTINCT c.CustomerID)) * 100 AS ChurnRate
FROM 
    geography geo
JOIN 
    customerinfo c ON geo.GeographyID = c.GeographyID
JOIN 
    bank_churn b ON c.CustomerID = b.CustomerID
LEFT JOIN 
    exitcustomer e ON b.ExitID = e.ExitID
WHERE
	b.ExitID = 1
GROUP BY 
    geo.GeographyLocation;
    

-- SUBJECTIVE QUESTION 4 : Based on customer profiles, which demographic segments appear to pose the highest financial risk to the bank, and why?------------------

-- SELECT 
--     geo.GeographyLocation AS Region,
--     g.GenderCategory AS Gender,
--     AVG(c.Age) AS AvgAge,
--     AVG(b.CreditScore) AS AvgCreditScore,
--     AVG(b.Balance) AS AvgBalance,
--     COUNT(DISTINCT CASE WHEN b.ExitID IS NOT NULL THEN b.CustomerID END) AS NumChurnedCustomers,
--     COUNT(DISTINCT b.CustomerID) AS TotalCustomers,
--     (COUNT(DISTINCT CASE WHEN b.ExitID IS NOT NULL THEN b.CustomerID END) * 100.0 / COUNT(DISTINCT b.CustomerID)) AS ChurnRate,
--     AVG(b.NumOfProducts) AS AvgNumOfProducts
-- FROM 
--     customerinfo c
-- JOIN 
--     bank_churn b ON c.CustomerID = b.CustomerID
-- JOIN 
--     activecustomer a ON c.CustomerID = a.ActiveID
-- JOIN 
--     gender g ON c.GenderID = g.GenderID
-- JOIN 
--     geography geo ON c.GeographyID = geo.GeographyID
-- LEFT JOIN 
--     exitcustomer e ON b.ExitID = e.ExitID
-- GROUP BY 
--     geo.GeographyLocation, g.GenderCategory
-- ORDER BY 
--     ChurnRate DESC, AvgCreditScore ASC, AvgBalance DESC;

SELECT 
    g.GeographyLocation, 
    c.Surname, 
    c.Age, 
    c.EstimatedSalary, 
    bc.CreditScore, 
    bc.Tenure, 
    bc.Balance, 
    bc.NumOfProducts, 
    COUNT(DISTINCT ac.ActiveID) AS ActiveAccounts, 
    COUNT(DISTINCT bc.ExitID) AS ChurnedCustomers,
    -- Identifying high-risk customers based on various factors
    CASE 
        WHEN bc.CreditScore < 600 THEN 'High Risk: Low Credit Score'
        WHEN bc.Balance > (c.EstimatedSalary * 1.5) THEN 'High Risk: High Balance/Low Salary'
        WHEN bc.Tenure < 1 THEN 'High Risk: Short Tenure'
        WHEN g.GeographyLocation = 'Spain' THEN 'High Risk: High Churn Region'
        ELSE 'Low Risk'
    END AS RiskLevel,
    -- Churn rate calculation by region
    (COUNT(DISTINCT bc.ExitID) / COUNT(DISTINCT c.CustomerID)) * 100 AS ChurnRate
FROM 
    geography g
JOIN 
    customerinfo c ON g.GeographyID = c.GeographyID
JOIN 
    bank_churn bc ON c.CustomerID = bc.CustomerID
LEFT JOIN 
    activecustomer ac ON bc.ActiveID = ac.ActiveID
LEFT JOIN 
    exitcustomer ec ON bc.ExitID = ec.ExitID
GROUP BY 
    g.GeographyLocation, c.CustomerID
HAVING 
    RiskLevel IN ('High Risk: Low Credit Score', 'High Risk: High Balance/Low Salary', 'High Risk: Short Tenure', 'High Risk: High Churn Region')
ORDER BY 
    g.GeographyLocation, RiskLevel DESC;



-- SUBJECTIVE QUESTION 5 : How would you use the available data to model and predict the lifetime (tenure) value in the bank of different customer segments? ------------------

SELECT 
    c.CustomerID,
    c.Age,
    c.EstimatedSalary,
    b.CreditScore,
    b.Tenure,
    b.Balance,
    b.NumOfProducts,
    cc.Category AS CreditCardCategory,
    a.ActiveCategory,
    e.ExitCategory,
    DATEDIFF(CURDATE(), c.BankDOJ) / 365 AS CurrentTenureYears
FROM 
    customerinfo c
JOIN 
    geography geo ON c.GeographyID = geo.GeographyID
JOIN 
    bank_churn b ON c.CustomerID = b.CustomerID
LEFT JOIN 
    creditcard cc ON b.CreditID = cc.CreditID
LEFT JOIN 
    activecustomer a ON b.ActiveID = a.ActiveID
LEFT JOIN 
    exitcustomer e ON b.ExitID = e.ExitID;

    
-- SUBJECTIVE QUESTION 6 : How could you assess the impact of marketing campaigns on customer retention and acquisition within the dataset? 
-- What extra information would you need to solve this?------------------------------------------------

-- Answered in Word File.
    
    
-- SUBJECTIVE QUESTION 7: Can you identify common characteristics or trends among customers who have exited that could explain their reasons for leaving? ----------------
SELECT 
    c.Age, 
    c.EstimatedSalary, 
    b.CreditScore, 
    b.Tenure, 
    b.Balance, 
    b.NumOfProducts, 
    COUNT(b.CustomerID) AS TotalExitedCustomers
FROM 
    customerinfo c
JOIN 
    bank_churn b ON c.CustomerID = b.CustomerID
JOIN 
    geography geo ON c.GeographyID = geo.GeographyID
LEFT JOIN 
    activecustomer a ON b.ActiveID = a.ActiveID
LEFT JOIN 
    exitcustomer e ON b.ExitID = e.ExitID
WHERE 
    b.ExitID = 1  
GROUP BY 
    c.Age, 
    c.EstimatedSalary, 
    b.CreditScore, 
    b.Tenure, 
    b.Balance, 
    b.NumOfProducts
ORDER BY 
    TotalExitedCustomers DESC;
    
-- SUBJECTIVE QUES 8 Are 'Tenure', 'NumOfProducts', 'IsActiveMember', and 'EstimatedSalary' important for predicting if a customer will leave the bank?-------------------
-- Answered in Word File.

-- SUBJECTIVE QUESTION 9 : Utilize SQL queries to segment customers based on demographics and account details. ---------------------------------------
  
SELECT 
	c.CustomerID, 
	c.Age,
	b.CreditScore,
	b.Balance,
	b.Tenure,
	g.GenderCategory,
	geo.GeographyLocation,
CASE 
	WHEN c.Age < 25 THEN 'Youth (Under 25)'
	WHEN c.Age BETWEEN 25 AND 35 THEN 'Young Adults (25-35)'
	WHEN c.Age BETWEEN 36 AND 50 THEN 'Middle Age (36-50)'
	ELSE 'Senior (Above 50)'
END AS AgeGroup,
CASE 
	WHEN b.CreditScore < 500 THEN 'Poor Credit'
	WHEN b.CreditScore BETWEEN 500 AND 700 THEN 'Average Credit'
	ELSE 'Good Credit'
END AS CreditScoreCategory,

CASE 
	WHEN b.Balance < 10000 THEN 'Low Balance'
	WHEN b.Balance BETWEEN 10000 AND 50000 THEN 'Medium Balance'
	ELSE 'High Balance'
END AS BalanceCategory,
CASE 
	WHEN b.Tenure < 2 THEN 'New Customer'
	WHEN b.Tenure BETWEEN 2 AND 5 THEN 'Moderate Customer'
	ELSE 'Loyal Customer'
END AS TenureSegment,
CASE 
	WHEN CreditID = 1 THEN 'Credit Card Holder'
	ELSE 'Non-Credit Card Holder'
END AS CreditCardSegment
FROM 
bank_churn b
	JOIN customerinfo c on c.CustomerID=b.CustomerID
	JOIN gender g on g.GenderID=c.GenderID
	JOIN geography geo on geo.GeographyID=c.GeographyID;

-- SUBJECTIVE QUESTION 10 : How can we create a conditional formatting setup to visually highlight customers at risk of 
-- churn and to evaluate the impact of credit card rewards on customer retention?-------------------------------------------------------------

-- Answered in Word File.
    
-- SUBJECTIVE QUESTION 11 : What is the current churn rate per year and overall as well in the bank? 
-- Can you suggest some insights to the bank about which kind of customers are more likely to 
-- churn and what different strategies can be used to decrease the churn rate?----------------------------------------------------------------

SELECT 
    (COUNT( bc.CustomerID) / (SELECT COUNT(DISTINCT CustomerID) FROM customerinfo)) * 100 AS OverallChurnRate
FROM 
    bank_churn bc
WHERE 
    bc.ExitID IS NOT NULL;

SELECT 
    YEAR(c.BankDOJ) AS YearJoined, 
    (COUNT(DISTINCT bc.CustomerID) / (SELECT COUNT(DISTINCT CustomerID) FROM customerinfo WHERE YEAR(BankDOJ) = YEAR(c.BankDOJ))) * 100 AS YearlyChurnRate
FROM 
    customerinfo c
JOIN 
    bank_churn bc ON c.CustomerID = bc.CustomerID
WHERE 
    bc.ExitID IS NOT NULL
GROUP BY 
    YearJoined
ORDER BY 
    YearJoined;
    
-- SUBJECTIVE QUESTION 12 : Create a dashboard incorporating all the KPIs and visualization-related metrics. 
-- Use a slicer in order to assist in selection in the dashboard. ------------------------------------------------------------------------

-- Created on PowerBi Desktop

-- SUBJECTIVE QUESTION 13 : How would you approach this problem, if the objective and subjective questions weren't given?----------------------------------------
-- Answered in word file

-- SUBJECTIVE QUESTION 14 : In the “Bank_Churn” table how can you modify the name of the “CreditID” column to “Has_creditcard”?
ALTER TABLE bank_churn
CHANGE CreditID Has_creditcard INT;
Select * from bank_churn;
