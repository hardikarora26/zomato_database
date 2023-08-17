drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

/* What is the total amount each customer spent on zomato? */

select userid, sum(p.price) from sales s join product p on s.product_id = p.product_id
group by userid;

/* How many days has each customer visited zomato? */

select userid, count(distinct created_date) as cnt from sales group by userid;

/* What was the first product purchased by each customer? */

select * from (
select * ,rank() over( partition by userid order by created_date) as rnk from sales) a where rnk = 1;

/* What is the most purchased item on the menu and how many times was it purchased by all customers? */
select * from (
select product_id, count(product_id) as cnt from sales group by product_id) a order by cnt desc limit 1;

select userid, count(b.product_id) as total_purchase from (
select * from (
select product_id, count(product_id) as cnt from sales group by product_id) a order by cnt desc limit 1) b join sales on b.product_id = sales.product_id 
group by userid order by userid;

/* Which item was most popular for each of the customer */

select * from 
(select * , rank() over( partition by userid order by CNT desc) rnk from (
select userid, product_id, count(product_id) CNT from sales group by userid,product_id) a ) b where rnk = 1;

/* Which item was purchased first by the customer after becoming a member? */
select * from (
select *, rank() over (partition by s.userid order by created_date) rnk from (
select s.userid, s.created_date, s.product_id,g.gold_signup_date from sales s join goldusers_signup g on s.userid = g.userid 
where created_date >= gold_signup_date) a) b where rnk = 1;

/* Which item was purchased just before the customer became a memeber */

select * from (
select *, rank() over (partition by s.userid order by created_date desc) rnk from (
select s.userid, s.created_date, s.product_id,g.gold_signup_date from sales s join goldusers_signup g on s.userid = g.userid 
where created_date < gold_signup_date) a) b where rnk = 1;

/* What is the total orders and amout spent for each member before becoming a member */

select a.userid, count(created_date) as total_orders, sum(p.price) sum from 
(select s.userid, s.created_date, s.product_id,g.gold_signup_date from sales s join goldusers_signup g on s.userid = g.userid
where created_date < gold_signup_date) a  join product p on a.product_id = p.product_id group by userid order by userid;

/* Q9- If bying each product generates points for eg 5rs = 2 zomato points and each order has different purchasing points 
   for eg for p1 5rs = 1 zomato point, for p2 10rs = 5 zomato points and for p3 5rs = 1 zomato points 

 calculate points collected by each customer and for which product most points have been given till now */
 
/* part 1 */

select userid, sum(total_points) as points_per_customer from
(select e.* ,round( e.total_price/e.rs_per_point) as total_points from
(select d.userid, d.product_id, d.total_price,
case
when d.product_id = 1 then 5
when d.product_id = 2 then 2
when d.product_id = 3 then 5
end as rs_per_point from
(select s.userid,s.product_id, sum(p.price) as total_price from sales s inner join product p on s.product_id = p.product_id 
group by s.userid, s.product_id order by s.userid, s.product_id) d ) e) g
group by userid;

/* part 2 */

select f.product_id, sum(f.total_points) as max_points from 
(select e.* ,round( e.total_price/e.rs_per_point) as total_points from
(select d.userid, d.product_id, d.total_price,
case
when d.product_id = 1 then 5
when d.product_id = 2 then 2
when d.product_id = 3 then 5
end as rs_per_point from
(select s.userid,s.product_id, sum(p.price) as total_price from sales s inner join product p on s.product_id = p.product_id 
group by s.userid, s.product_id order by s.userid, s.product_id) d ) e ) f 
group by f.product_id order by f.total_points desc limit 1;


/* Q10- In the first one year after the customer joins the gold program ( including their joining date ) irrespective 
 of what the customer has purchased they earn 5 zomato points for each 10rs spent
 
 who earner more zomato points ( 1 or 3 ) and what was their points earnings in their first year? */
 
 select n.*, p.price, round(p.price/2) as points_earned from
 (select s.userid, s.created_date, s.product_id,g.gold_signup_date from sales s inner join goldusers_signup g
 on s.userid = g.userid and s.created_date >= g.gold_signup_date and s.created_date <= DATE_ADD(g.gold_signup_date, interval 1 year) ) n
 inner join product p on n.product_id = p.product_id
 order by n.userid;
 
 /* Q11- Rank all the transactions of the customer */
 
 select *, rank() over( partition by userid order by created_date ) as 'rank' from sales;


/* Q12- Rank all the transactions for each member whenever they are a zomato gold member 
for every non gold member transaction mark as na */

select s.userid,s.created_date, s.product_id, g.gold_signup_date,
case when gold_signup_date is null then 'na' else rank() over(partition by userid order by created_date desc) end as rnk
 from sales s left join goldusers_signup g on s.userid = g.userid and s.created_date >= g.gold_signup_date
