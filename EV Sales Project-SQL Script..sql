create database electric_vehicles ;

ALTER TABLE dim_date 
CHANGE COLUMN `ï»¿date` `date` TEXT;

ALTER TABLE sales_by_makers 
CHANGE COLUMN `ï»¿date` `date` TEXT;

ALTER TABLE sales_by_state 
CHANGE COLUMN `ï»¿date` `date` TEXT;


/*1.List the top 3 and bottom 3 makers for the fiscal years
 2023 and 2024 in terms of the number of 2-wheelers sold.*/
 
 # Top 3 makers of 2-wheeler sold on FY2023

SELECT fiscal_year, maker, vehicle_category, SUM(electric_vehicles_sold) as total_sold 
FROM dim_date 
inner join sales_by_makers USING(date)
WHERE vehicle_category = '2-Wheelers' AND fiscal_year = '2023'
group by maker, fiscal_year, vehicle_category
order by total_sold DESC
limit 3;

# Bottom 3 makers of 2-wheeler sold on FY2023

SELECT fiscal_year, maker, vehicle_category, SUM(electric_vehicles_sold) as total_sold 
FROM dim_date 
inner join sales_by_makers USING(date)
WHERE vehicle_category = '2-Wheelers' AND fiscal_year = '2023'
group by maker, fiscal_year, vehicle_category
order by total_sold ASC
limit 3;



# Top 3 makers of 2-wheeler sold on FY2024

SELECT fiscal_year, maker, vehicle_category, SUM(electric_vehicles_sold) as total_sold 
FROM dim_date 
inner join sales_by_makers USING(date)
WHERE vehicle_category = '2-Wheelers' AND fiscal_year = '2024'
group by maker, fiscal_year, vehicle_category
order by total_sold DESC
limit 3;

#Bottom 3 makers of 2-wheeler sold on FY2024

SELECT fiscal_year, maker, vehicle_category, SUM(electric_vehicles_sold) as total_sold 
FROM dim_date 
inner join sales_by_makers USING(date)
WHERE vehicle_category = '2-Wheelers' AND fiscal_year = '2024'
group by maker, fiscal_year, vehicle_category
order by total_sold ASC
limit 3;


/*2.Identify the top 5 states with the highest 
penetration rate in 2-wheeler and 4-wheeler 
EV sales in FY 2024.*/

#Top 5 states with highest penetration rate in 2 wheeler at FY 2024

SELECT state, vehicle_category, fiscal_year,
CONCAT(ROUND(SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100, 2), '%') AS penetration_rate
FROM sales_by_state AS s
INNER JOIN dim_date AS d USING(date)
WHERE vehicle_category = '2-Wheelers' AND fiscal_year = '2024'
GROUP BY state, vehicle_category, fiscal_year
ORDER BY SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) DESC
LIMIT 5;

#For 4 wheelers

SELECT state, vehicle_category, fiscal_year,
CONCAT(ROUND(SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100, 2), '%') AS penetration_rate
FROM sales_by_state AS s
INNER JOIN dim_date AS d USING(date)
WHERE vehicle_category = '4-Wheelers' AND fiscal_year = '2024'
GROUP BY state, vehicle_category, fiscal_year
ORDER BY SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) DESC
LIMIT 5;


/*3.List the states with negative penetration (decline)
 in EV sales from 2022 to 2024?*/
 
 WITH pen_2022 AS (
    SELECT state, SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) AS pen_rate_2022
    FROM sales_by_state s
    LEFT JOIN dim_date d USING (date) 
    WHERE fiscal_year = 2022
    GROUP BY state ),
pen_2023 AS (
    SELECT state, SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) AS pen_rate_2023
    FROM sales_by_state s
    LEFT JOIN dim_date d USING (date) 
    WHERE fiscal_year = 2023
    GROUP BY state ),
pen_2024 AS (
    SELECT state, SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) AS pen_rate_2024
    FROM sales_by_state s
    LEFT JOIN dim_date d USING (date) 
    WHERE fiscal_year = 2024
    GROUP BY state ),
sales_2023vs2024 AS (
    SELECT  p1.state, (pen_rate_2024 - pen_rate_2023) / pen_rate_2023 * 100 AS neg_pen 
    FROM pen_2024 p1
    INNER JOIN pen_2023 p2 ON p1.state = p2.state ),
sales_2022vs2023 AS (
    SELECT p1.state, (pen_rate_2023 - pen_rate_2022) / pen_rate_2023 * 100 AS neg_pen 
    FROM pen_2022 p1
    INNER JOIN pen_2023 p2 ON p1.state = p2.state )
SELECT * 
FROM sales_2023vs2024 
WHERE neg_pen < 0
UNION
SELECT * 
FROM sales_2022vs2023 
WHERE neg_pen < 0;

 
 
/*4.What are the quarterly trends based on
 sales volume for the top 5 EV makers 
 (4-wheelers) from 2022 to 2024?*/ 
 
WITH top_makers AS (
    SELECT maker, SUM(electric_vehicles_sold) AS total_sales
    FROM sales_by_makers m
    LEFT JOIN dim_date d USING(date)
    WHERE vehicle_category = '4-Wheelers'
    GROUP BY maker
    ORDER BY total_sales DESC
    LIMIT 5),
makers_data AS (
    SELECT m.maker, d.fiscal_year, d.quarter, 
	      SUM(electric_vehicles_sold) AS sales_rate
    FROM sales_by_makers m
    LEFT JOIN dim_date d USING(date)
    WHERE vehicle_category = '4-Wheelers'
          AND d.fiscal_year BETWEEN 2022 AND 2024
    GROUP BY m.maker, d.fiscal_year, d.quarter)
SELECT 
    md.maker, md.fiscal_year, md.quarter, md.sales_rate
FROM makers_data md
INNER JOIN top_makers tm ON md.maker = tm.maker
ORDER BY md.fiscal_year ASC, 
         md.quarter ASC, 
         md.sales_rate DESC;

 
 
 /*5.How do the EV sales and penetration rates in Delhi 
 compare to Karnataka for 2024?*/
 
 SELECT fiscal_year, state , SUM(electric_vehicles_sold) AS total_sold,
        (SUM(electric_vehicles_sold)/SUM(total_vehicles_sold)*100) 
        AS penetration_rates
FROM dim_date AS d
INNER JOIN sales_by_state AS s USING(date)  
WHERE fiscal_year = '2024' AND state IN ( 'Delhi', 'Karnataka' )
GROUP BY  fiscal_year, state ;   
 
 
 /*6.List down the compounded annual growth rate (CAGR) in 4-wheeler 
    units for the top 5 makers from 2022 to 2024.*/
   
WITH initial_sales AS (
    SELECT m.maker, 
        SUM(electric_vehicles_sold) AS initial_value
    FROM dim_date AS dd
    INNER JOIN sales_by_makers AS m
        ON dd.date = m.date
    WHERE dd.fiscal_year = 2022 
      AND m.vehicle_category = '4-Wheelers'
    GROUP BY m.maker),
final_sales AS (
    SELECT m.maker, 
        SUM(electric_vehicles_sold) AS final_value
    FROM dim_date AS dd
    INNER JOIN sales_by_makers AS m ON dd.date = m.date
    WHERE dd.fiscal_year = 2024 
      AND m.vehicle_category = '4-Wheelers'
    GROUP BY m.maker),
cagr_calculation AS (
    SELECT i.maker,
        ((ROUND(POWER(f.final_value * 1.0 / i.initial_value, 1 / 2.0),4)) - 1) AS CAGR
    FROM initial_sales i
    INNER JOIN final_sales f ON i.maker = f.maker)
SELECT maker, CAGR
FROM cagr_calculation
ORDER BY CAGR DESC
LIMIT 5;
  
    
/*7.List down the top 10 states that had the highest compounded annual 
growth rate (CAGR) from 2022 to 2024 in total vehicles sold.*/

WITH initial_sales AS (
    SELECT m.state, SUM(m.total_vehicles_sold) AS initial_value
    FROM dim_date AS dd
    INNER JOIN sales_by_state AS m ON dd.date = m.date
    WHERE dd.fiscal_year = 2022
    GROUP BY m.state),
final_sales AS (
    SELECT m.state, SUM(m.total_vehicles_sold) AS final_value
    FROM dim_date AS dd
    INNER JOIN sales_by_state AS m ON dd.date = m.date
    WHERE dd.fiscal_year = 2024
    GROUP BY m.state),
cagr_calculation AS (
    SELECT i.state,((POWER(f.final_value * 1.0 / i.initial_value, 1 / 2.0)) - 1) * 100 AS CAGR
    FROM initial_sales i
    INNER JOIN final_sales f ON i.state = f.state)
    
SELECT state, ROUND(CAGR, 4) AS CAGR_Percentage
FROM cagr_calculation
ORDER BY CAGR_Percentage DESC
LIMIT 10;



/*8.What are the peak and low season months for EV sales based on the 
data from 2022 to 2024*/    
 
SELECT  DATE_FORMAT(STR_TO_DATE(dd.date, '%d-%b-%y'), '%M') AS months,dd.fiscal_year,
SUM(ev.electric_vehicles_sold) AS electric_sold
FROM dim_date AS dd
INNER JOIN sales_by_state AS ev
ON dd.date = ev.date
WHERE dd.fiscal_year BETWEEN 2022 AND 2024
GROUP BY months, dd.fiscal_year
ORDER BY electric_sold DESC
LIMIT 5 ;


/*9. What is the projected number of EV sales (including 2-wheelers and 4-
wheelers) for the top 10 states by penetration rate in 2030, based on the 
compounded annual growth rate (CAGR) from previous years?*/


WITH maker_sales_2022 AS (
    SELECT state, SUM(electric_vehicles_sold) AS total_ev_sales_2022
    FROM sales_by_state s
    JOIN dim_date d USING (date)
    WHERE d.fiscal_year = 2022
    GROUP BY state ),
maker_sales_2024 AS (
    SELECT state, SUM(electric_vehicles_sold) AS total_ev_sales_2024
    FROM sales_by_state s
    JOIN dim_date d USING (date)
    WHERE d.fiscal_year = 2024
    GROUP BY state ),
cagr_calculation AS (
    SELECT m2024.state, m2024.total_ev_sales_2024, m2022.total_ev_sales_2022,
        POWER(CAST(m2024.total_ev_sales_2024 AS FLOAT) / NULLIF(CAST(m2022.total_ev_sales_2022 AS FLOAT), 0),1.0 / 2) - 1 AS cagr
    FROM maker_sales_2024 m2024
    JOIN maker_sales_2022 m2022 ON m2024.state = m2022.state ),
projected_sales AS (
    SELECT state,total_ev_sales_2024,cagr,
        ROUND(total_ev_sales_2024 * POWER(1 + cagr, 6), 2) AS projected_sales_2030 -- Rounded to 2 decimal places
    FROM cagr_calculation )
    
SELECT state, projected_sales_2030
FROM projected_sales
ORDER BY projected_sales_2030 DESC
LIMIT 10;




/*10.Estimate the revenue growth rate of 4-wheeler and 2-wheelers 
EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average 
unit price. H*/ 
 
WITH revenue_by_category AS(SELECT d.fiscal_year,
SUM(CASE WHEN m.vehicle_category = '2-Wheelers' THEN m.electric_vehicles_sold * 85000 ELSE 0 END) AS revenue_2_wheelers,
SUM(CASE WHEN m.vehicle_category = '4-Wheelers' THEN m.electric_vehicles_sold * 1500000 ELSE 0 END) AS revenue_4_wheelers
FROM sales_by_makers AS m
LEFT JOIN dim_date AS d USING (date)
GROUP BY d.fiscal_year),

comparison_data AS (
SELECT
fiscal_year,
revenue_2_wheelers,
revenue_4_wheelers,
FIRST_VALUE(revenue_2_wheelers) OVER (ORDER BY fiscal_year) AS revenue_2022_2_wheelers,
FIRST_VALUE(revenue_4_wheelers) OVER (ORDER BY fiscal_year) AS revenue_2022_4_wheelers,
LAG(revenue_2_wheelers) OVER (ORDER BY fiscal_year) AS prev_revenue_2_wheelers,
LAG(revenue_4_wheelers) OVER (ORDER BY fiscal_year) AS prev_revenue_4_wheelers
FROM revenue_by_category)

SELECT
fiscal_year,
revenue_2_wheelers,
revenue_4_wheelers,ROUND(CASE WHEN fiscal_year = 2024 THEN
((revenue_2_wheelers - revenue_2022_2_wheelers) * 100.0 / revenue_2022_2_wheelers) ELSE NULL
END, 2) AS growth_rate_2_wheelers_2022_vs_2024,
ROUND(CASE
WHEN fiscal_year = 2024 THEN
((revenue_4_wheelers - revenue_2022_4_wheelers) * 100.0 / revenue_2022_4_wheelers) ELSE NULL
END, 2) AS growth_rate_4_wheelers_2022_vs_2024,

ROUND(CASE
WHEN fiscal_year = 2024 AND prev_revenue_2_wheelers IS NOT NULL THEN
((revenue_2_wheelers - prev_revenue_2_wheelers) * 100.0 / prev_revenue_2_wheelers)
ELSE NULL END, 2) AS growth_rate_2_wheelers_2023_vs_2024,
ROUND(CASE WHEN fiscal_year = 2024 AND prev_revenue_4_wheelers IS NOT NULL THEN
((revenue_4_wheelers - prev_revenue_4_wheelers) * 100.0 / prev_revenue_4_wheelers) ELSE NULL
END, 2) AS growth_rate_4_wheelers_2023_vs_2024
FROM comparison_data
ORDER BY fiscal_year;








 
 