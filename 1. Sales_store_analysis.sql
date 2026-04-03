DROP TABLE IF EXISTS Sales;

--create table
CREATE TABLE sales 
(
transaction_id VARCHAR(50),
customer_id VARCHAR(50),
customer_name VARCHAR(50),
customer_age INT,
gender VARCHAR(50),
product_id VARCHAR(50),
product_name VARCHAR(150),
product_category VARCHAR(150),
quantiy INT, 
prce NUMERIC(10,2),
payment_mode VARCHAR(50),
purchase_date DATE,
time_of_purchase TIME, 
status VARCHAR(50)
);


--data population
COPY 
Sales (transaction_id, customer_id, customer_name, customer_age, gender, product_id,
	   product_name, product_category, quantiy, prce, payment_mode, purchase_date, 
	   time_of_purchase, status)
FROM 'D:\Skill_Verce\SQL\Project\2. Sales_Store_Data_Analysis_SQL\sales_store_Data.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM Sales;

--creating a copy
SELECT * INTO sales_store
FROM Sales;

SELECT * FROM sales_store;

--Checking Duplicate
SELECT transaction_id,COUNT(*)
FROM sales_store
GROUP BY transaction_id
HAVING COUNT(*)>1;

--Check if entire row is duplicate
SELECT * FROM
(SELECT *,
		ROW_NUMBER() OVER(PARTITION BY transaction_id) as Ranking
FROM sales_store) R
WHERE R.Ranking >=2;

--Removing Duplicate
SELECT DISTINCT * 
FROM sales_store;

--Backup Table
CREATE TABLE sales_store_bkp AS
SELECT DISTINCT * 
FROM sales_store;

--Remove old Table with duplicates
DROP TABLE sales_store;

SELECT * 
FROM sales_store_bkp;

ALTER TABLE sales_store_bkp
RENAME TO sales_store;

SELECT * 
FROM sales_store; -- (De-dup table)


-- Checking For Null Values
SELECT * 
FROM sales_store
WHERE
transaction_id IS NULL OR 
customer_id IS NULL OR 
customer_name IS NULL OR 
customer_age IS NULL OR 
gender IS NULL OR 
product_id IS NULL OR 
product_name IS NULL OR 
product_category IS NULL OR 
quantiy IS NULL OR 
prce IS NULL OR 
payment_mode IS NULL OR 
purchase_date IS NULL OR 
time_of_purchase IS NULL OR 
status IS NULL;

SELECT *
FROM sales_store
WHERE customer_name = 'Ehsaan Ram';

UPDATE sales_store
SET customer_id = 'CUST9494'
WHERE transaction_id = 'TXN977900'

SELECT *
FROM sales_store
WHERE customer_name = 'Damini Raju';

UPDATE sales_store
SET customer_id = 'CUST1401'
WHERE transaction_id = 'TXN985663';

SELECT *
FROM sales_store
WHERE customer_id = 'CUST1003';

UPDATE sales_store
SET customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male' 
WHERE transaction_id = 'TXN432798';

DELETE FROM sales_store
WHERE transaction_id IS NULL AND
customer_id IS NULL AND 
customer_name IS NULL AND 
customer_age IS NULL;

--Data cleaning in Columns

SELECT * 
FROM sales_store;

SELECT DISTINCT gender 
FROM sales_store;

UPDATE sales_store
SET gender = 'Male'
WHERE gender = 'M';  -- (Converting M into Male as they hold Same meaning)

UPDATE sales_store
SET gender = 'Female'
WHERE gender = 'F';  -- (Converting F into Female as they hold Same meaning)


SELECT DISTINCT payment_mode 
FROM sales_store;

UPDATE sales_store
SET payment_mode = 'Credit Card'
WHERE payment_mode = 'CC'; -- (Converting CC into Credit Card as they hold Same meaning)

ALTER TABLE sales_store
RENAME COLUMN prce to Price; -- (Rectifying column names)

ALTER TABLE sales_store
RENAME COLUMN quantiy to quantity;

SELECT *
FROM sales_store; -- (Checking data after cleaning)


-- Analysis

--🔥 1. What are the top 5 most selling products by quantity?
SELECT product_name, sum(quantity) as total_Qty
FROM sales_store
WHERE status = 'delivered'
GROUP BY product_name
ORDER BY total_Qty DESC
LIMIT 5;


--Business Problem: We don't know which products are most in demand.

--Business Impact: Helps prioritize stock and boost sales through targeted promotions.
----------------------------------------------------------------------------------------------------------
--📉 2. Which products are most frequently cancelled?

SELECT product_name, count(transaction_id) as total_count
FROM sales_store
WHERE status = 'cancelled'
GROUP BY product_name
ORDER BY total_count DESC
LIMIT 5;

--Business Problem: Frequent cancellations affect revenue and customer trust.

--Business Impact: Identify poor-performing products to improve quality or remove from catalog.
----------------------------------------------------------------------------------------------------------
--🕒 3. What time of the day has the highest number of purchases?
SELECT 
	CASE
		WHEN DATE_PART('Hour', time_of_purchase) BETWEEN 0 AND 5 THEN 'Night'
		WHEN DATE_PART('Hour', time_of_purchase) BETWEEN 6 AND 11 THEN 'Morning'
		WHEN DATE_PART('Hour', time_of_purchase) BETWEEN 12 AND 17 THEN 'Afternoon'
		WHEN DATE_PART('Hour', time_of_purchase) BETWEEN 18 AND 23 THEN 'Evening'
	END as purchase_time,
	COUNT(*) AS order_count
FROM sales_store
GROUP BY
	CASE
		WHEN DATE_PART('Hour', time_of_purchase) BETWEEN 0 AND 5 THEN 'Night'
		WHEN DATE_PART('Hour', time_of_purchase) BETWEEN 6 AND 11 THEN 'Morning'
		WHEN DATE_PART('Hour', time_of_purchase) BETWEEN 12 AND 17 THEN 'Afternoon'
		WHEN DATE_PART('Hour', time_of_purchase) BETWEEN 18 AND 23 THEN 'Evening'
	END
ORDER BY order_count DESC;

--Business Problem Solved: Find peak sales times.

--Business Impact: Optimize staffing, promotions, and server loads.
-----------------------------------------------------------------------------------------------------------
--👥 4. Who are the top 5 highest spending customers?
SELECT customer_name, sum(quantity*price) as total_spent
FROM sales_store
GROUP BY customer_name
ORDER BY total_spent DESC
LIMIT 5;

--Business Problem Solved: Identify VIP customers.

--Business Impact: Personalized offers, loyalty rewards, and retention.

-----------------------------------------------------------------------------------------------------------
--🛍️ 5. Which product categories generate the highest revenue?
SELECT *
FROM sales_store;

SELECT product_category, sum(quantity*price) as total_revenue
FROM sales_store
GROUP BY product_category
ORDER BY total_revenue DESC;

--Business Problem Solved: Identify top-performing product categories.

--Business Impact: Refine product strategy, supply chain, and promotions.
--allowing the business to invest more in high-margin or high-demand categories.
-----------------------------------------------------------------------------------------------------------
--🔄 6. What is the return/cancellation rate per product category?
SELECT * FROM sales_store;

SELECT  product_category,
		COUNT(CASE WHEN status = returned, 	
		COUNT(CASE WHEN status = 'cancelled' THEN 1 END)*100/COUNT(*) AS cancellation_rate
FROM sales_store
GROUP BY product_category
ORDER BY cancellation_rate DESC;


SELECT product_category,
		COUNT(CASE WHEN status = 'returned' THEN 1 END)*100/COUNT(*) AS return_rate
FROM sales_store
GROUP BY product_category
ORDER BY return_rate DESC;

--Business Problem Solved: Monitor dissatisfaction trends per category.
--Business Impact: Reduce returns, improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.
-----------------------------------------------------------------------------------------------------------
--💳 7. What is the most preferred payment mode?
SELECT payment_mode, count(*) as total_orders 
FROM sales_store
GROUP BY payment_mode
ORDER BY total_orders DESC; 

--Business Problem Solved: Know which payment options customers prefer.

--Business Impact: Streamline payment processing, prioritize popular modes.
-----------------------------------------------------------------------------------------------------------
--🧓 8. How does age group affect purchasing behavior?
SELECT MAX(customer_age), MIN (customer_age)
FROM sales_store;

SELECT 
	CASE 
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25' 
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '50+'
	END AS age_group,
	SUM(price*quantity) AS Total_purchase
FROM sales_store
GROUP BY CASE 
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25' 
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '50+'
	END
ORDER BY Total_purchase DESC;

--Business Problem Solved: Understand customer demographics.
--Business Impact: Targeted marketing and product recommendations by age group.
----------------------------------------------------------------------------------------------------------
--🔁 9. What’s the monthly sales trend?
SELECT DATE_PART('year', purchase_date), 
	   DATE_PART('Month', purchase_date),
	   SUM(price*quantity) as revenue
FROM sales_store
GROUP BY DATE_PART('year', purchase_date), 
	   DATE_PART('Month', purchase_date)
ORDER BY revenue DESC;

--Business Problem: Sales fluctuations go unnoticed.

--Business Impact: Plan inventory and marketing according to seasonal trends.
-----------------------------------------------------------------------------------------------------------
--🔎 10. Are certain genders buying more specific product categories by quantity and order count?
SELECT * FROM sales_store;


SELECT gender, product_category, sum(quantity) as total_Qty,COUNT(*) as total_order
FROM sales_store
GROUP BY gender, product_category
ORDER BY gender, total_order DESC;

SELECT gender, product_category, COUNT(*) as total_order
FROM sales_store
GROUP BY gender, product_category
ORDER BY gender, total_order DESC;

--Business Problem Solved: Gender-based product preferences.
--Business Impact: Personalized ads, gender-focused campaigns.






















