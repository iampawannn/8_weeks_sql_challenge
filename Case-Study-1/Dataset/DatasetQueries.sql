--CREATE TABLE sales (
--  "customer_id" VARCHAR(1),
--  "order_date" DATE,
--  "product_id" INTEGER
--);

--INSERT INTO sales
--  ("customer_id", "order_date", "product_id")
--VALUES
--  ('A', '2021-01-01', '1'),
--  ('A', '2021-01-01', '2'),
--  ('A', '2021-01-07', '2'),
--  ('A', '2021-01-10', '3'),
--  ('A', '2021-01-11', '3'),
--  ('A', '2021-01-11', '3'),
--  ('B', '2021-01-01', '2'),
--  ('B', '2021-01-02', '2'),
--  ('B', '2021-01-04', '1'),
--  ('B', '2021-01-11', '1'),
--  ('B', '2021-01-16', '3'),
--  ('B', '2021-02-01', '3'),
--  ('C', '2021-01-01', '3'),
--  ('C', '2021-01-01', '3'),
--  ('C', '2021-01-07', '3');
 

--CREATE TABLE menu (
--  "product_id" INTEGER,
--  "product_name" VARCHAR(5),
--  "price" INTEGER
--);

--INSERT INTO menu
--  ("product_id", "product_name", "price")
--VALUES
--  ('1', 'sushi', '10'),
--  ('2', 'curry', '15'),
--  ('3', 'ramen', '12');
  

--CREATE TABLE members (
--  "customer_id" VARCHAR(1),
--  "join_date" DATE
--);

--INSERT INTO members
--  ("customer_id", "join_date")
--VALUES
--  ('A', '2021-01-07'),
--  ('B', '2021-01-09');

--the total amount each customer spent at the restaurant

SELECT 
	s.customer_id,
	SUM(price) AS total_amount
FROM [Danny's_Dinner].dbo.sales AS s
INNER JOIN [Danny's_Dinner].dbo.menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

--How many days has each customer visited the restaurant

SELECT 
	s.customer_id,
	COUNT(DISTINCT s.order_date) AS total_no_of_visits
FROM [Danny's_Dinner].dbo.sales AS s
GROUP BY s.customer_id;

--the first item from the menu purchased by each customer
WITH first_order AS 
(
	SELECT s.*,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
	FROM [Danny's_Dinner].dbo.sales AS s
	INNER JOIN [Danny's_Dinner].dbo.menu AS m
	ON s.product_id = m.product_id
)

SELECT f.customer_id, f.order_date, m.product_name
FROM first_order AS f
INNER JOIN [Danny's_Dinner].dbo.menu AS m
ON f.product_id = m.product_id
WHERE f.rn = 1


--the most purchased item on the menu and how many times was it purchased by all customers

SELECT
	s.product_id,
	m.product_name,
	COUNT(s.product_id) AS number_of_purchases
FROM [Danny's_Dinner].dbo.sales AS s
INNER JOIN [Danny's_Dinner].dbo.menu AS m
	ON s.product_id = m.product_id 
GROUP BY s.product_id,
	m.product_name
ORDER BY COUNT(s.product_id) DESC

--the most popular for each customer

WITH most_ordered AS 
(
	SELECT customer_id,
			product_id,
			COUNT(*) AS num_of_purchases
	FROM [Danny's_Dinner].dbo.sales
	GROUP BY customer_id, product_id
), ranked_sales AS 
(
	SELECT 
		customer_id,
		product_id, 
		num_of_purchases,
		RANK() OVER(PARTITION BY customer_id ORDER BY num_of_purchases DESC) AS rank
	FROM most_ordered
)

SELECT 
	rs.customer_id,
	rs.product_id,
	m.product_name,
	rs.num_of_purchases
FROM ranked_sales AS rs
INNER JOIN [Danny's_Dinner].dbo.menu AS m
	ON rs.product_id = m.product_id 
WHERE rank = 1


--item that was purchased first by the customer after they became a member
WITH first_order AS 
(
	SELECT s.customer_id, s.order_date, me.join_date, s.product_id,
	Row_number() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
	FROM [Danny's_Dinner].dbo.sales AS s
	INNER JOIN [Danny's_Dinner].dbo.members AS me
	ON s.customer_id = me.customer_id
	WHERE s.order_date >= me.join_date
)
SELECT f.customer_id, f.order_date, m.product_name, f.join_date
FROM first_order AS f
JOIN [Danny's_Dinner].dbo.menu AS m
ON f.product_id = m.product_id
WHERE f.rn=1

--item that was purchased just before the customer became a member

WITH cte AS 
(
	SELECT s.customer_id, s.order_date, me.join_date, s.product_id,
	Row_number() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
	FROM [Danny's_Dinner].dbo.sales AS s
	INNER JOIN [Danny's_Dinner].dbo.members AS me
	ON s.customer_id = me.customer_id
	WHERE s.order_date < me.join_date 
)
SELECT f.customer_id, f.order_date, m.product_name, f.join_date
FROM cte AS f
JOIN [Danny's_Dinner].dbo.menu AS m
ON f.product_id = m.product_id 
WHERE f.rn = 1


-- the total items and amount spent for each member before they became a member

WITH cte AS 
(
	SELECT s.customer_id, s.order_date, me.join_date, s.product_id,
	Row_number() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
	FROM [Danny's_Dinner].dbo.sales AS s
	INNER JOIN [Danny's_Dinner].dbo.members AS me
	ON s.customer_id = me.customer_id
	WHERE s.order_date < me.join_date 
)
SELECT
	f.customer_id,
	SUM(m.price) AS 'total_spent_before_becoming_member($)' 
FROM cte AS f
INNER JOIN [Danny's_Dinner].dbo.menu AS m
ON f.product_id = m.product_id
GROUP BY f.customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier
-- how many points would each customer have

SELECT 
	s.customer_id,
	SUM(
		CASE WHEN product_name = 'sushi' THEN m.price*20
		ELSE price*10
		END
	) AS total_points
FROM [Danny's_Dinner].dbo.sales AS s
INNER JOIN [Danny's_Dinner].dbo.menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id