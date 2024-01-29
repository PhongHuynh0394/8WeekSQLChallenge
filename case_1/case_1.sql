-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id , SUM(m.price)
FROM 
	sales s, menu m 
WHERE s.product_id = m.product_id 
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id , COUNT(DISTINCT s.order_date) as visit
FROM sales s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH item_purchase AS(
	SELECT 
		s.*, 
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rank_day,
		m.product_name
	FROM sales s 
	JOIN menu m 
	ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM item_purchase
WHERE rank_day = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.customer_id) AS time_purchased
FROM sales s, menu m 
WHERE s.product_id = m.product_id 
GROUP BY m.product_name
ORDER BY time_purchased DESC
LIMIT 1

-- 5. Which item was the most popular for each customer?
WITH item_rank AS (
	SELECT
		s.customer_id, m.product_name,
		COUNT(s.order_date) as time_purchase
	FROM sales s 
	JOIN menu m 
	ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, time_purchase
FROM (
	SELECT 
		customer_id, 
		product_name,
		time_purchase,
		RANK() OVER(PARTITION BY customer_id ORDER BY time_purchase DESC) AS rank_purchase
	FROM item_rank
) as temp
WHERE rank_purchase = 1; -- To use where in alias, need to use CTE or sub at FROM 

-- 6. Which item was purchased first by the customer after they became a member?
WITH item_after_member AS (
	SELECT 
		s.customer_id, s.order_date, me.product_name, m.join_date,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as order_purchase_date
	FROM sales s 
	JOIN members m ON s.customer_id = m.customer_id
	JOIN menu me ON me.product_id = s.product_id
	WHERE s.order_date >= m.join_date
)
SELECT customer_id, order_date, join_date, product_name
FROM item_after_member
WHERE order_purchase_date = 1;

-- 7. Which item was purchased just before the customer became a member?
WITh item_before_member AS (
	SELECT 
		s.customer_id, s.order_date, me.product_name, m.join_date,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as order_purchase_date
	FROM sales s 
	JOIN members m ON s.customer_id = m.customer_id
	JOIN menu me ON me.product_id = s.product_id
	WHERE s.order_date < m.join_date
)
SELECT customer_id, order_date, join_date, product_name
FROM item_before_member
WHERE order_purchase_date = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, 
	COUNT(s.product_id) as Total_item, 
	SUM(m2.price) as total_spent
FROM sales s
JOIN members m ON m.customer_id = s.customer_id 
JOIN menu m2 ON m2.product_id = s.product_id 
WHERE s.order_date < m.join_date
GROUP BY s.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id,
	SUM(CASE
		WHEN s.product_id = 1 THEN m.price*20
		ELSE m.price*10
	END
	) AS total_point
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id 
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi how many points do customer A and B have at the end of January?
WITH point_purchase AS (
    SELECT 
        s.customer_id, s.order_date,
        (
            CASE 
                WHEN DATE(s.order_date) BETWEEN s.order_date AND (s.order_date + INTERVAL 7 DAY) THEN mn.price * 20
                ELSE
                    CASE
                        WHEN s.product_id = 1 THEN mn.price * 20
                        ELSE mn.price * 10
                    END
            END
        ) AS point_in_day
    FROM sales s
    JOIN menu mn ON s.product_id = mn.product_id
    JOIN members mem ON s.customer_id = mem.customer_id
    WHERE s.order_date BETWEEN mem.join_date AND '2021-01-31'
)
SELECT customer_id, SUM(point_in_day)
FROM point_purchase
GROUP BY customer_id;
