INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


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


#1. What is total amount each customer spent on zomato?

SELECT a.userid,sum(b.price) total_sum from sales a inner join product b on a.product_id=b.product_id
group by a.userid;


#2. How many days has each customer visited zomato?

SELECT userid,count(distinct created_date)  from sales group by userid;

#3.What was the first product purchased by the customer?

select * from
(SELECT * ,rank() over(partition by userid order by created_date) rnk from sales) a where rnk =1;

#4.  What is the most purchased item on the menu and how many time it was purchased by all customers?

SELECT userid,count(product_id) cnt from sales where product_id =
(SELECT product_id from sales group by product_id order by count(product_id) desc limit 1)
group by userid;

#5. Which itemn was the most popular for each customer?

SELECT * from
(SELECT *,rank() over(partition by userid order by cnt desc) rnk from
(SELECT userid,product_id,count(product_id) cnt from sales group by userid,product_id) a) b
where rnk =1;

#6.  Which item was first purchased by the customer after they become a  member?

SELECT * from
(SELECT c.*,rank() over(partition by userid order by created_date) rnk from
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b where a.userid=b.userid and created_date>=gold_signup_date) c) d where rnk=1;

#7. which item was purchased just before the customer became the member?

SELECT * from
(SELECT c.*,rank() over(partition by userid order by created_date desc) rnk from
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b where a.userid=b.userid and created_date<=gold_signup_date) c) d where rnk=1;

#8. What is the total orders and amount spent for each member before they became a member?

SELECT userid,count(created_date) order_purchased, sum(price) total_amount_spent from
(SELECT c.*,d.price from
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join 
goldusers_signup b on a.userid=b.userid and created_date<=gold_signup_date) c inner join product d on c.product_id=d.product_id) e
group by userid;

#9. Buying products give different points for each products
#eg: p1 5rs=1 zomato points
# 	 p2 10rs=5 zomato points
#	 p3 5rs=1 zomato points
#	 p4 2rs=1 zomato points

#calculate points collected by each customer and which product have most points till now

SELECT userid,ROUND(sum(total_points))*2.5 total_rupees_earned from
(SELECT e.*,amt/points total_points from
(SELECT d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(SELECT c.userid,c.product_id,sum(price) amt from
(SELECT a.*,b.price from sales a inner join product b on a.product_id=b.product_id) c
group by userid,product_id) d ) e) f group by userid order by userid asc;



# which product have most points till now

SELECT * from
(SELECT *,rank() over(order by total_points_earned desc) rnk from
(SELECT product_id,Round(sum(total_points)) total_points_earned from
(SELECT e.*,amt/points total_points from
(SELECT d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(SELECT c.userid,c.product_id,sum(price) amt from
(SELECT a.*,b.price from sales a inner join product b on a.product_id=b.product_id) c
group by userid,product_id) d ) e) f group by product_id)f)g where rnk=1;


#In the first one year after a customer joins the gold program (including their job date) irrespective of what the customer has purchased they earned 5 zomato points for every 10 rs spent who earned more 1 or 3 and what was their points earnings in their first year?

# 1 zp=2rs
# 0.5 zp=1rs

SELECT c.*,d.price*0.5 total_points_earned from 
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join
goldusers_signup b on a.userid=b.userid and created_date>=b.gold_signup_date and a.created_date<=DATE_ADD(b.gold_signup_date,INTERVAL 1 YEAR))c
inner join product d on c.product_id=d.product_id order by userid asc;


#Rank Transaction of the customers

SELECT *,rank() over(partition by userid order by created_date) rnk from sales;

# 12. Rank all the transaction for each member whenever they are a zomato gold member for every non gold member transaction mark as NA

select e.*,case when rnk=0 then 'na' else rnk end as rnkk from
(SELECT c.*,cast((case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end) as char(2)) as rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a left join
goldusers_signup b on a.userid=b.userid and created_date>=gold_signup_date)c)e;