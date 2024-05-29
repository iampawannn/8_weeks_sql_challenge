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

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
-- how many points do customer A and B have at the end of January?

WITH cte AS 
(
	SELECT s.customer_id, s.order_date, s.product_id, me.join_date
	FROM [Danny's_Dinner].dbo.sales AS s
	INNER JOIN [Danny's_Dinner].dbo.members AS me
	ON s.customer_id = me.customer_id
	WHERE s.order_date BETWEEN me.join_date AND DATEADD(WEEK, 1, me.join_date)
)
SELECT 
	f.customer_id, 
	SUM(
		CASE WHEN m.product_name <> 'sushi' THEN m.price * 20
		ELSE m.price * 10
		END
	) AS total_points
FROM cte AS f
INNER JOIN [Danny's_Dinner].dbo.menu AS m
ON f.product_id = m.product_id
WHERE MONTH(f.order_date) = 1
GROUP BY f.customer_id;
