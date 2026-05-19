create table dim_products ( 
Product_id varchar(20) Primary key,
Product_Name Text,
Category Varchar(10),
Subcategory varchar(10),
Unit_Cost Numeric(10,2),
Selling_Price int
);
select * from dim_products;

alter table dim_products
alter column Category type Varchar(20);
alter table dim_products
alter column Selling_Price type Numeric(10,2);

create table dim_suppliers(
Supplier_id varchar(20) Primary key,
Supplier_Name text,
Region text,
Supplier_Rating Numeric(5,2),
Defect_Rate Numeric(5,2),
Average_Lead_Time int
);
select * from dim_suppliers;
select count(*) from dim_suppliers;

create table dim_warehouses(
warehouse_id varchar(20),
warehouse_name text,
city varchar(10),
region varchar(10),
capacity int
);
select * from dim_warehouses;

alter table dim_warehouses
alter column warehouse_id set Primary key;
alter table dim_warehouses
add Primary key(warehouse_id);
alter table dim_warehouses
alter column city type varchar(20);

create table dim_date(
date DATE PRIMARY KEY,
year int,
quarter int,
 month int,
 month_name varchar(20),
 day int
);
select * from dim_date;
alter table dim_date
drop column quarter;
alter table dim_date
add quarter int;

create table fact_orders (
order_id varchar(10) PRIMARY KEY,
product_id varchar(10),
warehouse_id varchar(10),
supplier_id varchar(10),
order_date date,
ship_date date,
delivery_date date,
quantity_ordered int,
sales_amount numeric(12,2),
shipping_cost numeric(10,2),
delivery_status varchar(20)
);  select * from fact_orders;

create table fact_inventory(
 inventory_id varchar(10) primary key,
 product_id varchar(10),
 warehouse_id varchar(10) ,
 stock_level int,
 reorder_level int,
inventory_date date,
holding_cost numeric(12,2),
inventory_age_days int
);
select * from fact_inventory;

create table fact_shipment(
 shipment_id varchar(10) primary key,
 order_id varchar(10)  REFERENCES fact_orders(order_id),
 carrier varchar(50),
 shipment_status varchar(20),
 delay_days int,
 delivery_time int,
 carrier_cost numeric(10,2),
 shipment_mode varchar(20),
 weather_delay_flag varchar(5)
);
select * from fact_shipment;

--Total Sales
select sum(sales_amount) as total_sales
from fact_orders;

-- Total orders
select count(order_id) as total_orders
from fact_orders;

--Average order value (shows how much spent per order)
select avg(sales_amount) as average_order_value
from fact_orders;

--Highest Selling Price products(Top5)
select product_id,product_name,category,selling_price
from dim_products
order by selling_price desc
limit 5;

--Lowest selling rice
select Min(selling_price)
from dim_products;

--total quantity sold
select sum(quantity_ordered) as total_quantity
from fact_orders;

--total shipping cost (total logistic expense)
select sum(shipping_cost)
from fact_orders;

--average shipping cost per order
select avg(shipping_cost)
from fact_orders;

--shipping cost% by sales(how much revenue takes up by shipping)
select round(
(sum(shipping_cost)/sum(sales_amount))*100,2) as shipping_cost_percentage
from fact_orders;

--showing sales by delivery_status
select delivery_status,sum(sales_amount) as total_sales
from fact_orders
group by delivery_status
order by total_sales desc;

--showing total_orders by delivery status
select delivery_status, count(order_id) as Total_ordersby_status
from fact_orders
group by delivery_status
order by Total_ordersby_status desc;

--warehouse performance by sales
select warehouse_id, sum(sales_amount)as total_sales,count(order_id) as total_orders
from fact_orders 
group by warehouse_id
order by sum(sales_amount) desc;

--Supplier performance analysis
select supplier_id, sum(sales_amount)as total_sales,count(order_id) as total_orders
from fact_orders 
group by supplier_id
order by sum(sales_amount) desc;

--Actual delivery days from the order date
select order_id,product_id,order_date,delivery_date,delivery_status,
(delivery_date-order_date) as delivery_days
from fact_orders
where delivery_date is not null;

--order size categorization
select order_id,sales_amount,
case 
when sales_amount>=100000 then 'high value'
when sales_amount>50000 then 'medium value'
else 'low value'
end as order_size
from fact_orders;

--using inner join to combine data of dim_products and fact_orders(product by sales analysis)

select p.product_name,sum(o.sales_amount)as total_sales,sum(o.quantity_ordered)as total_quantity
from fact_orders o
inner join dim_products p
ON p.product_id=o.product_id
group by p.product_name
order by total_sales desc;


--shows category by sales
select p.category,sum(o.sales_amount)as total_sales,sum(o.quantity_ordered)as total_quantity,
round(avg(o.shipping_cost),2)as avg_ship_cost
from fact_orders o
inner join dim_products p
ON p.product_id=o.product_id
group by p.category
order by total_sales desc;

--per unit profit analysis
select product_id,product_name,(selling_price-unit_cost)as profit_per_unit
from dim_products;

--Total_profit by product (sp-unitcost)*quantity_ordered
select p.product_name, sum((p.selling_price-p.unit_cost)*o.quantity_ordered)as total_profit
from fact_orders o
inner join dim_products p
on o.product_id=p.product_id
group by p.product_name
order by total_profit desc;

--profit margin % by category (profit/sales*100)
select p.category, 
sum((p.selling_price-p.unit_cost)*o.quantity_ordered) / sum(o.sales_amount)*100 as profit_margin_percent 
from fact_orders o
inner join dim_products p
on o.product_id=p.product_id
group by p.category
order by profit_margin_percent desc;

--top 5 product_id by total_sales
select product_id, sum(sales_amount) as total_sales
from fact_orders
group by product_id
order by total_sales desc
limit 5;

--ranking product_id by sales

select p.product_id,sum(o.sales_amount) as total_sales,
Row_number() over(order by sum(o.sales_amount) desc) as sales_ranking
from fact_orders o
inner join dim_products p
on o.product_id=p.product_id
group by p.product_id;

--ranking category by sales
select p.category,sum(o.sales_amount) as total_sales,
Rank() over(order by sum(o.sales_amount) desc) as sales_ranking
from fact_orders o
inner join dim_products p
on o.product_id=p.product_id
group by p.category;

--CTEs concept showing top 3 products by sales with ranking

with cte_ranking as(
select p.product_name, sum(o.sales_amount) as total_sales, 
rank() over(order by sum(o.sales_amount)  desc) as ranking
from fact_orders o
inner join dim_products p
on o.product_id=p.product_id
group by p.product_name
)
select * from cte_ranking
where ranking <=3;

--showing total_running_sales(cummulative growth) by month 

select date_trunc('month',order_date) as months, sum(sales_amount) as monthly_sales,
sum(sum(sales_amount)) over(order by date_trunc('month',order_date)) as running_total_sales
from fact_orders
group by date_trunc('month',order_date)
order by months;

--Carrier Performance Analysis
select carrier, sum(carrier_cost) as total_carrier_cost, count(shipment_id) as total_shipments
from fact_shipment
group by carrier
order by total_carrier_cost;

--carrier rank on the basis of total orders
select carrier, count(order_id)as total_orders,avg(delay_days)as average_delay_days
from fact_shipment
group by carrier
order by total_orders desc;

--carrier ranking inside each shipment mode by total_shipment
select carrier,shipment_mode,count(shipment_id),
rank() over(partition by shipment_mode order by count(shipment_id) desc) as ranking
from fact_shipment
group by carrier,shipment_mode;


--shipment mode analysis
select shipment_mode, count(shipment_id)as total_shipment,avg(carrier_cost) as avg_carrier_cost,
avg(delivery_time) as avg_delivery_time
from fact_shipment
group by shipment_mode
order by avg_delivery_time;

--weather delay impact (shows total orders affecting and not affecting)
select weather_delay_flag, count(shipment_id)
from fact_shipment
group by weather_delay_flag;

--low stock level analysis
select *, 
case
when stock_level<= reorder_level then 'Reorder Needed'
else 'healthy stock'
end as inventory_status
from fact_inventory;

--warehouse inventory anaysis
select warehouse_id, sum(stock_level)as total_stock_level, avg(holding_cost) as avg_hold_cost
from fact_inventory
group by warehouse_id
order by total_stock_level desc;

--inventory aging analysis using case statement
select inventory_age_days,inventory_id,
case 
when inventory_age_days<=60 then 'fresh stock'
when inventory_age_days<=100 then 'aging stock'
else 'old stock'
end as aging_status
from fact_inventory;

--inventory risk ranking by product id
select product_id, round(avg(inventory_age_days),2) as avg_inv_days,
row_number() over(order by avg(inventory_age_days) desc )as ranking
from fact_inventory
group by product_id;

-----END








 

















--










