SELECT * FROM pizza_db.goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date);
INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1, '2017-09-22'), (3, '2017-04-21');

INSERT INTO users (userid, signup_date) 
VALUES 
  (1, '2014-09-02'),
  (2, '2015-01-15'),
  (3, '2014-04-11');

INSERT INTO sales (userid, created_date, product_id) 
VALUES 
(1, '2017-04-19', 2),
(3, '2019-12-18', 1),
(2, '2020-07-20', 3),
(1, '2019-10-23', 2),
(1, '2018-03-19', 3),
(3, '2016-12-20', 2),
(1, '2016-11-09', 1),
(1, '2016-05-20', 3),
(2, '2017-09-24', 1),
(1, '2017-03-11', 2),
(1, '2016-03-11', 1),
(3, '2016-11-10', 1),
(3, '2017-12-07', 2),
(3, '2016-12-15', 2),
(2, '2017-11-08', 2),
(2, '2018-09-10', 3);

CREATE TABLE product(product_id integer,product_name text,price integer); 
INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from goldusers_signup;
select * from product;
select * from sales;
select * from users;

/* Q1. What is the total amount each customer spent on zomato ? */
select sales.userid,sum(product.price) total_price
from sales 
inner join product on sales.product_id = product.product_id
group by sales.userid;


/* Q2. How many days has each customer visited zomato? ? */
select userid, count(distinct created_date) days_visited from sales
group by userid;

/* Q3. what was the first product purchased by each customer? */
select *from(select *, row_number() over (partition by userid order by created_date) as rn from sales) a 
where rn = 1;

select product_id,min(created_date) first_purchase_date from sales where userid = 1
group by product_id
order by  product_id;
select * from sales;

/* Q4. what is most purchased item on menu & how many times was it purchased by all customers ?*/
select product_id, count(*) total_purchase from sales
group by product_id
order by total_purchase desc limit 1 ;

/* Q5.which item was most popular for each customer?*/
WITH RankedProducts AS (
    SELECT
        userid,
        product_id,
        COUNT(*) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY userid ORDER BY COUNT(*) DESC) AS rnk
    FROM
        sales
    GROUP BY
        userid, product_id
)
SELECT
    userid,
    product_id,
    purchase_count
FROM
    RankedProducts
WHERE
    rnk = 1;
with ranked_products as(
select userid,product_id, count(*) as purchase_count, row_number() OVER (PARTITION BY userid ORDER BY COUNT(*) DESC) AS rnk
from sales group by 1,2) 
select userid, product_id, purchase_count
from ranked_products where rnk = 1;
with cte as(
select userid,product_id, count(product_id) as purchase_count, rank() OVER (partition by userid ORDER BY COUNT(*) DESC) AS rnk
from sales group by 1,2)
SELECT userid,product_id, purchase_count 
from cte WHERE rnk= 1;

/*Q6. which item was purchased first by customer after they become a member ? */
select * from goldusers_signup;
with cte as(
select sales.userid,sales.product_id,
rank() over(partition by sales.userid order by sales.created_date) rnk
from sales
join goldusers_signup on sales.userid = goldusers_signup.userid
where sales.created_date>goldusers_signup.gold_signup_date)
select cte.userid,
    product.product_id AS purchased_product_id from cte
join product on cte.product_id = product.product_id
where cte.rnk=1;
select * from sales;
/*Q7. which item was purchased just before the customer became a member?*/
with cte as(
select sales.userid,sales.product_id, sales.created_date,goldusers_signup.gold_signup_date,
rank () over (partition by userid order by sales.created_date desc) rnk 
from sales
join goldusers_signup on sales.userid = goldusers_signup.userid
where sales.created_date<=goldusers_signup.gold_signup_date)
select cte.userid,
    cte.product_id,
    cte.gold_signup_date
    from cte
where rnk =1;

/* 8. what is total orders and amount spent for each member before they become a member? */
SELECT
    gs.userid,
    COUNT(s.userid) AS total_orders,
    SUM(p.price) AS total_amount_spent
FROM
    goldusers_signup gs
JOIN
    sales s ON gs.userid = s.userid
JOIN
    product p ON s.product_id = p.product_id
WHERE
    s.created_date < gs.gold_signup_date
GROUP BY
    gs.userid;

/* 11. rnk all transaction of the customers*/
select *,rank() over(partition by userid order by created_date asc) rn from sales;
/* Q12. rank all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as na*/
SELECT
  sales.userid,
  sales.created_date,
  goldusers_signup.gold_signup_date,
  CASE
    WHEN goldusers_signup.gold_signup_date IS NULL
      THEN  'na'
    ELSE
      RANK() OVER (
        PARTITION BY sales.userid
        ORDER BY sales.created_date DESC
      )
  END AS rnk
FROM sales
LEFT JOIN goldusers_signup ON goldusers_signup.userid = sales.userid;

/* 9. If buying each product generates points for eg 5rs=2 zomato point 
  and each product has different purchasing points for eg for p1 5rs=1 zomato point,for p2 10rs=zomato point and p3 5rs=1 zomato point  2rs =1zomato point, 
  calculate points collected by each customer and for which product most points have been given till now. */
/* Total points earned by each customer */
select userid,sum(points_earned) as total_points_earned from 
(select *, total_spend/points as points_earned from 
(select *, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id =3 then 5 else 0 end as points from
(select b.userid, b.product_id, sum(price) as total_spend from
(select s.userid, p.product_id, p.product_name,p.price from sales s inner join product p on s.product_id = p.product_id) b 
group by b.userid, b.product_id)c)d)e group by userid;
/* Total points earned by each product  & then which product got the most number of points*/
select * from(
select *, rank() over (order by total_points_earned desc) rnk from 
(select product_id,sum(points_earned) as total_points_earned from 
(select *, total_spend/points as points_earned from 
(select *, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id =3 then 5 else 0 end as points from
(select b.userid, b.product_id, sum(price) as total_spend from
(select s.userid, p.product_id, p.product_name,p.price from sales s inner join product p on s.product_id = p.product_id) b 
group by b.userid, b.product_id)c)d)e group by product_id)f)g where rnk = 1;

/*  In the first year after a customer joins the gold program (including the join date ) 
irrespective of what customer has purchased earn 5 zomato points for every 10rs spent who earned more more 1 or 3 what int earning in first yr ? 1zp = 2rs */


select sales.userid,sales.product_id,sales.created_date, goldusers_signup.gold_signup_date
from sales
join goldusers_signup on sales.userid = goldusers_signup.userid
where sales.created_date>goldusers_signup.gold_signup_date
and created_date <= date_add(gold_signup_date,    )
order by userid
