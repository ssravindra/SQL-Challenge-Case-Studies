use dannys_diner;

-- 1. What is the total amount each customer spent at the restaurant?
select customer_id,sum(price) total_spent from (
	select A.customer_id,B.product_id,B.price from sales A left join menu B on A.product_id=B.product_id
    ) X
group by customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id ,count(distinct order_date) No_of_day from sales group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select customer_id ,product_name from (
	select A.customer_id,B.product_id,A.order_date,B.product_name,row_number() over(partition by customer_id order by order_date) 
    sales_list from sales A join menu B on A.product_id = B.product_id) X 
where sales_list =1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name,Total_sale from (
	select product_name, Total_sale ,dense_rank() over(order by Total_sale desc) Total_sales_by_rank from (
		select B.product_name, count(A.product_id) Total_sale from sales A left join menu B on A.product_id=B.product_id group by B.product_name) X
        ) Y 
where Total_sales_by_rank =1;

-- 5. Which item was the most popular for each customer?
select customer_id,product_name from (
	select *, rank() over(partition by customer_id order by total_order desc) rnk from (
		select A.customer_id,B.product_name,count(B.product_name) total_order from sales A left join menu B on A.product_id = B.product_id group by A.customer_id,B.product_name) X
		) Y
where rnk =1;

-- 6. Which item was purchased first by the customer after they became a member?
select customer_id, product_name from  (
  select A.customer_id,B.join_date,A.order_date, A.product_id,C.product_name,dense_rank() over(partition by customer_id order by order_date) rnk 
	 from  sales A 
		join members B on A.customer_id = B.customer_id 
		join menu C on A.product_id = C.product_id
  where order_date >= join_date ) Y 
where rnk =1;
 
-- 7. Which item was purchased just before the customer became a member?
select customer_id,product_name from (
select B.customer_id,B.join_date,A.order_date last_purchase_date_before_join, A.product_id,C.product_name,dense_rank() over(partition by customer_id order by order_date desc) rnk
	from  sales A 
		  join members B on A.customer_id = B.customer_id 
		  join menu C on A.product_id = C.product_id		  
	where A.order_date < B.join_date ) X 
where rnk =1 ;


-- 8. What is the total items and amount spent for each member before they became a member?
select customer_id, count(product_id) total_items,sum(price) amount_spent from (
  select B.customer_id, A.product_id,C.product_name,C.price
       from  sales A 
	   join members B on A.customer_id = B.customer_id 
	   join menu C on A.product_id = C.product_id		  
   where A.order_date < B.join_date) X 
group by customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id, sum(points)Total_points from (
select A.customer_id, A.product_id,C.product_name,C.price ,case when product_name ='Sushi' then (price*2)*10 else price *10 end points
from  sales A 
	   left join members B on A.customer_id = B.customer_id 
	   left join menu C on A.product_id = C.product_id)X group by customer_id;

/**
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?
**/
SELECT january_sales.customer_id,SUM(CASE 
        WHEN january_sales.order_date <= (SELECT DATE_ADD(members.join_date, INTERVAL 7 DAY) FROM members WHERE members.customer_id = january_sales.customer_id) THEN 2 * january_sales.price 
        ELSE january_sales.price END) AS total_point FROM (
        SELECT A.customer_id, A.order_date, B.price, B.product_name FROM sales A
			JOIN menu B ON A.product_id = B.product_id WHERE EXTRACT(MONTH FROM A.order_date) = 1) AS january_sales
			JOIN members ON january_sales.customer_id = members.customer_id
GROUP BY january_sales.customer_id;



