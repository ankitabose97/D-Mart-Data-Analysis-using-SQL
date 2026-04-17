-- D- Mart Data Import from CSV

-- Create Table Statement
CREATE TABLE Retail_store_transaction
(
	transaction_id VARCHAR(50),
	customer_id VARCHAR(50),
	customer_name VARCHAR(50),
	customer_age INT, 
	gender VARCHAR(50),
	product_id VARCHAR(50),
	product_name VARCHAR(80),
	product_category VARCHAR(50),
	quantiy INT,
	prce NUMERIC(10,2),
	payment_mode VARCHAR(50),
	purchase_date DATE, 
	time_of_purchase TIME, 
	status VARCHAR(50)
);

COPY
Retail_store_transaction
(transaction_id, customer_id, customer_name, customer_age, gender, product_id, product_name, 
product_category, quantiy, prce, payment_mode, purchase_date, time_of_purchase, status)
FROM 'D:\Interview Drop\SQL\Project\Retail Sales\D - Mart Store Sales.csv'
DELIMITER ','
CSV HEADER;


SELECT * FROM Retail_store_transaction;


-- Create a copy of original Dataset for analysis

SELECT *
INTO transactions
FROM Retail_store_transaction;

SELECT * FROM transactions;

---------------------------------------------------------------------------------------------------------
-- Data Cleaning
--1. Check for duplicates
SELECT transaction_id, COUNT(*) AS records 
FROM transactions
GROUP BY transaction_id 
HAVING COUNT(*) > 1; -- Group by Approach

SELECT * 
FROM
(SELECT *, 

		ROW_NUMBER() OVER (PARTITION BY transaction_id) AS records 
FROM transactions) X
WHERE X.records> 1; -- Window Function Approach

SELECT * FROM transactions
WHERE transaction_id IN ('TXN855235','TXN240646','TXN342128','TXN981773');

--2. De-dup the transactions Table

CREATE TABLE transactions_bkp as
(SELECT DISTINCT * 
FROM transactions);

--3. Drop the transactions Table with duplicates
DROP TABLE transactions 

--4. Rename the transactions_bkp Table as transactions
ALTER TABLE transactions_bkp
RENAME TO transactions;


--5. Columns spelling correction
ALTER TABLE transactions
RENAME COLUMN quantiy TO quantity

ALTER TABLE transactions
RENAME COLUMN prce TO price;

SELECT * FROM transactions;


--6. Check for Distinct values in gender, product_category, status, payment_mode

SELECT DISTINCT gender
FROM transactions;

UPDATE transactions
SET gender = 'Male'
WHERE gender = 'M';

UPDATE transactions
SET gender = 'Female'
WHERE gender = 'F';

SELECT DISTINCT status
FROM transactions;

SELECT DISTINCT product_category
FROM transactions;

SELECT DISTINCT payment_mode
FROM transactions;

UPDATE transactions
SET payment_mode = 'Credit Card'
WHERE payment_mode = 'CC';

--7. Check for Null values

SELECT * 
FROM transactions
WHERE
transaction_id IS NULL OR 
customer_id IS NULL OR
customer_name IS NULL OR
customer_age IS NULL OR
gender IS NULL OR
product_id IS NULL OR
product_name IS NULL OR
product_category IS NULL OR
quantity IS NULL OR
price IS NULL OR
payment_mode IS NULL OR
purchase_date IS NULL OR
time_of_purchase IS NULL OR
status IS NULL;

--8. EDA for handling null values
SELECT * 
FROM transactions
WHERE customer_id = 'CUST1003';

UPDATE transactions
SET customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male'
WHERE transaction_id = 'TXN432798';

SELECT * 
FROM transactions
WHERE customer_name = 'Damini Raju';

UPDATE transactions
SET customer_id = 'CUST1401'
WHERE transaction_id = 'TXN985663'; 

SELECT * 
FROM transactions
WHERE customer_name = 'Ehsaan Ram';


UPDATE transactions
SET customer_id = 'CUST9494'
WHERE transaction_id = 'TXN977900'; 

DELETE
FROM transactions
WHERE
transaction_id IS NULL OR 
customer_id IS NULL OR
customer_name IS NULL OR
customer_age IS NULL OR
gender IS NULL; 


SELECT * 
FROM transactions
;

-----------------------------------------------------------------------------------------------------------
--Data Analysis--

--🔥 1. What are the top 5 most selling products by quantity?
SELECT product_name, SUM(quantity) as total_qty
FROM transactions
WHERE status = 'delivered'
GROUP BY product_name
ORDER BY total_qty DESC
LIMIT 5;

--Business Problem: We don't know which products are most in demand.

--Business Impact: Helps prioritize stock and boost sales through targeted promotions.

-----------------------------------------------------------------------------------------------------------

--📉 2. Which products are most frequently cancelled?
SELECT product_name, COUNT(transaction_id) as total_orders
FROM transactions
WHERE status = 'cancelled'
GROUP BY product_name
ORDER BY total_orders DESC
LIMIT 5;

--Business Problem: Frequent cancellations affect revenue and customer trust.

--Business Impact: Identify poor-performing products to improve quality or remove from catalog.

-----------------------------------------------------------------------------------------------------------


--🕒 3. What time of the day has the highest number of purchases?

SELECT
	CASE
		WHEN DATE_PART('Hour',time_of_purchase) BETWEEN 0 AND 5 THEN 'Night'
		WHEN DATE_PART('Hour',time_of_purchase) BETWEEN 6 AND 11 THEN 'Morning'
		WHEN DATE_PART('Hour',time_of_purchase) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END as time_of_purchase,
	COUNT(transaction_id) as total_orders
FROM transactions
GROUP BY 
	CASE
		WHEN DATE_PART('Hour',time_of_purchase) BETWEEN 0 AND 5 THEN 'Night'
		WHEN DATE_PART('Hour',time_of_purchase) BETWEEN 6 AND 11 THEN 'Morning'
		WHEN DATE_PART('Hour',time_of_purchase) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END
ORDER BY total_orders DESC;


--Business Problem Solved: Find peak sales times.

--Business Impact: Optimize staffing, promotions, and server loads.
-----------------------------------------------------------------------------------------------------------

--👥 4. Who are the top 5 highest spending customers?
SELECT customer_name, TO_CHAR(SUM(quantity * price),'$9,99,99,990.00') as total_spent
FROM transactions
GROUP BY customer_name
ORDER BY total_spent DESC
LIMIT 5;

--Business Problem Solved: Identify VIP customers.

--Business Impact: Personalized offers, loyalty rewards, and retention.

-----------------------------------------------------------------------------------------------------------

--🛍️ 5. Which product categories generate the highest revenue?
SELECT product_category, TO_CHAR(SUM(quantity * price),'$9,99,99,990.00') as total_spent
FROM transactions
GROUP BY product_category
ORDER BY total_spent DESC;

--Business Problem Solved: Identify top-performing product categories.

--Business Impact: Refine product strategy, supply chain, and promotions.
--allowing the business to invest more in high-margin or high-demand categories.

-----------------------------------------------------------------------------------------------------------

--🔄 6. What is the return/cancellation rate per product category?

SELECT product_category, 
		COUNT(CASE WHEN status = 'returned' THEN 1 END),COUNT(transaction_id) AS total_transaction,
		TO_CHAR(((COUNT(CASE WHEN status = 'returned' THEN 1 END)*100)/COUNT(transaction_id)),'99.99%') AS return_rate 
FROM transactions
GROUP BY product_category
ORDER BY return_rate DESC;

SELECT product_category,
	   COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled_orders,
	   COUNT(transaction_id) AS total_orders,
	   TO_CHAR(((COUNT(CASE WHEN status = 'cancelled' THEN 1 END)*100)/COUNT(transaction_id)),'99.99%') AS cancel_rate 
FROM transactions
GROUP BY product_category   
ORDER BY cancel_rate DESC;

--Business Problem Solved: Monitor dissatisfaction trends per category.


---Business Impact: Reduce returns, improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.

-----------------------------------------------------------------------------------------------------------
--💳 7. What is the most preferred payment mode?

SELECT payment_mode,
	   COUNT(transaction_id) AS total_orders
FROM transactions
GROUP BY payment_mode   
ORDER BY total_orders DESC;

--Business Problem Solved: Know which payment options customers prefer.

--Business Impact: Streamline payment processing, prioritize popular modes.

-----------------------------------------------------------------------------------------------------------

--🧓 8. How does age group affect purchasing behavior?

SELECT MIN(customer_age),MAX(customer_age)
FROM transactions

SELECT 
	CASE 
		WHEN customer_age BETWEEN 18 AND 25 THEN 'Within 25'
		WHEN customer_age BETWEEN 26 AND 35 THEN 'Within 35'
		WHEN customer_age BETWEEN 36 AND 50 THEN 'Within 50'
		ELSE 'Above 50'
	END AS age_category,
	COUNT(transaction_id) AS total_orders,
	TO_CHAR(SUM(quantity*price),'$9,99,99,999.00') AS total_revenue
FROM transactions
GROUP BY 
	CASE 
		WHEN customer_age BETWEEN 18 AND 25 THEN 'Within 25'
		WHEN customer_age BETWEEN 26 AND 35 THEN 'Within 35'
		WHEN customer_age BETWEEN 36 AND 50 THEN 'Within 50'
		ELSE 'Above 50'
	END
ORDER BY total_orders DESC;

--Business Problem Solved: Understand customer demographics.

--Business Impact: Targeted marketing and product recommendations by age group.

-----------------------------------------------------------------------------------------------------------
--🔁 9. What’s the monthly sales trend?
SELECT 
	  EXTRACT(YEAR FROM purchase_date) AS Purchase_year,
	  EXTRACT(MONTH FROM purchase_date) AS Purchase_month,
	  TO_CHAR(SUM(quantity*price),'$9,99,99,999.00') AS total_revenue,
	  LAG(TO_CHAR(SUM(quantity*price),'$9,99,99,999.00')) 
	  OVER (PARTITION BY EXTRACT(YEAR FROM purchase_date) ORDER BY EXTRACT(MONTH FROM purchase_date)) AS PREV_revenue,
	  TO_CHAR((SUM(quantity*price) - LAG(SUM(quantity*price)) 
	  OVER (PARTITION BY EXTRACT(YEAR FROM purchase_date) ORDER BY EXTRACT(MONTH FROM purchase_date)))*100/
	  LAG(SUM(quantity*price)) 
	  OVER (PARTITION BY EXTRACT(YEAR FROM purchase_date) ORDER BY EXTRACT(MONTH FROM purchase_date)),'99.99%') AS growth_rate
FROM transactions
GROUP BY EXTRACT(YEAR FROM purchase_date), EXTRACT(MONTH FROM purchase_date)
ORDER BY Purchase_year,Purchase_month;


--Business Problem: Sales fluctuations go unnoticed.


--Business Impact: Plan inventory and marketing according to seasonal trends.
-----------------------------------------------------------------------------------------------------------

--🔎 10. Are certain genders buying more specific product categories?
SELECT gender, product_category,
		COUNT(transaction_id) as total_orders,
		SUM(quantity*price) as total_spents
FROM transactions
GROUP BY gender, product_category
ORDER BY gender, total_orders DESC;

--Business Problem Solved: Gender-based product preferences.

--Business Impact: Personalized ads, gender-focused campaigns.

	  








