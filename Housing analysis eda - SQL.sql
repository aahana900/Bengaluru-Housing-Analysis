-- Bengaluru House Analysis(EDA)

/*"The goal of this analysis is to answer the following business questions, using data-driven insights 
to help young professionals and first-time buyers identify the most practical and affordable localities in Bengaluru's real estate market."*/


-- Let's create and use the database
drop database if exists house;
create database House;
use House;
select * from benagluru_house_date_cleaneddataset;

-- 1. What is the price-per-sqft by locality, and which localities offer the best value for 2BHK/3BHK homes

select location, round((avg(price/total_sqft)),4) as "price_per_sqft"
from benagluru_house_date_cleaneddataset
where sizes in ('2 BHK','3 BHK') and location is not null
group by location
order by price_per_sqft asc;

-- Through this analysis we have observed - 
-- The top localities that offer the best price per sqft for 2bhk and 3bhk houses are Kadabagere, Krirloskar, Phase 1 Kammasandra, Tunganagara, Madanayakahalli



-- 2.  How is the total price of homes distributed across different Bengaluru localities and which localities have the highest concentration of 
-- homes priced within an affordable budget band (e.g. ₹40–80 lakh) suitable for first-time buyers?
-- NOTE- THE AFFORDABLE BUDGET BAND FOR HOUSES AMONG YOUNG PROFESSIONALS OR FIRST TIME HOUSE BUYERS HAVE ON AN AVERAGE BEEN BETWEEN 40-80LAKH

select location, round(avg(price), 2) as "total_price_per_locality", count(location) as "Total_homes"
from  benagluru_house_date_cleaneddataset
group by location
having total_price_per_locality between 40.00 and 80.00
order by total_homes desc;

-- From the analysis we have obsereved that, Localities like electronic city,kanakpura road, raja rajeshwari nagar, uttarahalli and electronic city phase 2 are 
-- among the top localities with the highest concentration of homes and lie between the affordable budget band of 40-80lakhs.



-- 3.Which Bengaluru localities give the most sqft per ruppee value
select location, round(avg(total_sqft/(price*100000)),4) as "Sqft_per_ruppe_value"
from benagluru_house_date_cleaneddataset
group by location
order by sqft_per_ruppe_value desc;

-- From the above analysis , Bagalur, Sarjapur, Nelamangala, Indranagar and yelanka are the top localities 
-- that provide maximum sqft per ruppe spent by the buyer


-- 4.Is there a locality where 2BHK sizes are unusually generous relative to price — a good option for buyers stretching their budget for space?
with my_house as (
select location, round(avg(price),2) as "Average_price_per_locality", round(avg(total_sqft),2) as "Average_size_per_locality"
from benagluru_house_date_cleaneddataset
where sizes = '2 BHK'
group by location
order by average_size_per_locality desc
) 
select *,
dense_rank() over(order by average_price_per_locality) as "rank_of_houses"
from my_house;

-- Based on the analysis, localities like doddaballapur,kadabagere,bilal nagar, pilanne garderns and marsur are the localities that offer a generous size 
-- for a 2 bhk home relative to the prices



-- 5. Among 'Scheduled dates' listings, what's the typical wait time and do some localities consistently take longer to deliver?

select location, ceil(avg(datediff(str_to_date(concat(availability, '-2026'), '%d-%b-%Y'), curdate()))) as average_wait_time
from benagluru_house_date_cleaneddataset
where `Available status` = 'Scheduled dates' 
group by location
order by average_wait_time desc;

-- Based on this analysis, Bagur,kanakpura road and electronic phase 2 are the top localities with maximum waiting time. 
-- Note: Since the 'availability' field only stored day-month (no year), the year  2026 was taken for all entries based on the dataset's collection period.

-- 6. What is the most common BHK present in each locality and which localities are dominated by 1 BHK/2 BHK /3 BHK homes

WITH total_counts AS (
SELECT location,sizes,
COUNT(*) AS total_homes
FROM benagluru_house_date_cleaneddataset
GROUP BY location, sizes
), rankes AS (
SELECT location,sizes,total_homes,
DENSE_RANK() OVER (PARTITION BY location ORDER BY total_homes DESC) AS total_rank
FROM total_counts
)
SELECT *
FROM rankes
WHERE total_Rank = 1;

-- This analysis gives us the dominant bhk configuration with each locality with the total number of houses of such type

-- 7. Are buyers overpaying for extra balconies — i.e., does price rise noticeably with balcony count even when living space (sqft) stays roughly the same

select balcony,round(avg(price)) as "Average price",round(avg(price/total_sqft),4) as "Average price per sqft"
from benagluru_house_date_cleaneddataset
where balcony != "Not Provided"
group by balcony 
order by balcony;

-- Through this analysis we can't suggest that people are overpaying for a balcony because houses with more balconies demand a larger price per sqft


-- 8. How does area_type (Super Built-up / Built-up / Plot) affect effective price per sqft.

select area_type, round(avg(price/total_sqft), 4) as "Average_price_per_sqft"
from benagluru_house_date_cleaneddataset
group by area_type 
order by average_price_per_sqft;

-- Through our analysis, Plot Area has the highest average price per sqft, followed by Carpet Area, 
-- Built-up Area, and Super Built-up Area. This indicates that the pricing per sqft varies significantly across different area types.

-- 9. Which localities show abnormally high price-per-sqft, indicating premium/luxury 
-- housing compared to more budget-friendly areas?

select location , round(avg(price/total_sqft),4) as "average_price_perlocality"
from benagluru_house_date_cleaneddataset
group by location
having round(avg(price/total_sqft),4) > (select round(avg(price/total_sqft),4) as "average_price_persqft"
from benagluru_house_date_cleaneddataset)
order by 2 desc;

-- From this analysis, we can observe localities like kormangala,jaynagar,indranagar,srirampura,btm layout,Lavelle road and many more come under the premium/
-- luxury localities making them comparatively less for a budget friendly first time house buyers

-- 10.Which bengaluru localities have the best overall value for first time house buyers by balancing affordibility,availability and housing options 
select location, round(avg(price),4) as "Average_price", count(*) as "Total availability"
from benagluru_house_date_cleaneddataset
where availability in ('Ready To Move','Immediate possession') and sizes in ('1 BHK','2 BHK','3 BHK')
group by location
having average_price < (select round(avg(price),4) from benagluru_house_date_cleaneddataset)
order by 2 asc, 3 desc;

-- -- In the final analysis, After combining factors like through price, availability, size, and amenities one by one, a clear 
-- pattern showed up — localities like Alur, Makali, Kadabagere, and Bilal Nagar 
-- consistently came out cheaper than the city average AND actually had enough listings 
-- to be a good option for young professionals or first time home buyers with a lesser budget. what stood out most was that 
--  affordability alone isn't enough — a locality also needs to have homes ready (or close to ready) and the right size range (1-3 BHK) 
-- for this to actually make sense for a young professional or first-time buyer. 

