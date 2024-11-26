use india_election;

select * from india_election_incident;
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

set sql_safe_updates=0;

-- data cleaning and processing

alter table india_election_incident
drop column Coordinates;

select sum(case when Date is null or Date='' then 1 else 0 end)as missing_Date,
sum(case when State is null or State='' then 1 else 0 end)as missing_State,
sum(case when Lokshabha_Seat_Name is null or Lokshabha_Seat_Name='' then 1 else 0 end)as missing_Lokshabha_seat,
sum(case when Incident_Description is null or Incident_Description='' then 1 else 0 end )as missing_Incident,
sum(case when Action_taken is null or Action_taken='' then 1 else 0 end )as missing_Action_taken,
sum(case when Location_of_Incident is null or Location_of_Incident='' then 1 else 0 end )as missing_Location_of_Incident,
sum(case when Source_news_article is null or Source_news_article='' then 1 else 0 end )as missing_Source_news_article
from india_election_incident;

update india_election_incident
set State='West Bengal'
where State='';

update india_election_incident
set Action_Taken='No action taken'
where Action_taken='';

update india_election_incident
set Location_of_Incident='Unlnown location'
where Location_of_Incident='';

update india_election_incident
set Source_news_article='No source'
where Source_news_article='';


-- How many incidents occurred in each state over the past 5 years? Display the trend using a monthly or yearly breakdown. 
-- Use State, Date, and Incident_Description columns.

select State,month(str_to_date(Date,'%d-%m-%Y'))as month,count(Incident_Description)as count_incident
from india_election_incident
where str_to_date(Date,'%d-%m-%Y')>date_sub(current_date(),interval 5 year)
group by State,month;

-- Retrieve incidents where the description mentions keywords like "violence", "arrest", or "protest". Use the Incident_Description column with LIKE or REGEXP.

select State,Incident_Description
from india_election_incident
where Incident_Description like '%Firing%' or Incident_Description like '%Clash%' or Incident_Description like '%Protest%';

-- Find the top 5 states with the highest number of incidents that required a significant "Action_taken". Assume a significant action includes 
-- specific keywords like "arrest", "deployed", or "evacuated". Use State and Action_taken columns.

select State,Action_taken,count(*)as no_of_incident,dense_rank()over(order by count(*)desc)as ranked
from india_election_incident
where Action_taken like '%Arrest%' or Action_taken like '%Repolling%' or Action_taken like '%case%'
group by State
limit 5;

-- Identify the incidents and actions reported by more than one source. Use the Source_news_article column with a GROUP BY to find repeated mentions.

select Incident_Description,Action_taken,Source_news_article,count(*)as count
from india_election_incident
group by Source_news_article
having count(*)>1;

-- Find which Lokshabha seats have the most incidents, and drill down by state to identify
-- high-incident areas. Use State, Lokshabha_Seat_Name, and Location_of_Incident.

select State,Lokshabha_Seat_Name,count(*)as most_incident
from india_election_incident
group by State,Lokshabha_Seat_Name
order by most_incident desc;

-- Analyze the incidents during the election periods (e.g., one month before the Lokshabha elections).
-- Assume election dates are known, and you filter based on a specific time range. Use the Date column.

select date_format(str_to_date(Date,'%d-%m-%Y'),'%m')as month,Incident_Description
from india_election_incident
where month(str_to_date(Date,'%d-%m-%Y')) between 4 and 5; 

-- What is the average response time for incidents based on the Location_of_Incident? Assume there's a Response_Time column available.
-- Use advanced CASE conditions or create a JOIN if there's a separate response data table.

select Incident_Description,Location_of_Incident,avg(response_time)as avg_response_time
from india_election_incident
group by Incident_Description,Location_of_Incident;


-- Determine the percentage of incidents with actions taken versus those with no recorded actions for each state. Use State and Action_taken.

select State,Action_taken,(count(*)*100)/(select count(*) from india_election_incident)
from india_election_incident
group by State,Action_taken;

-- calculate the percent of no action taken for the incident

select (count(case when Action_taken='No action taken' then 1 end)*100)/count(*)as percent_of_no_action
from india_election_incident;

select State,Incident_Description,(count(*)*100)/(select count(*) from india_election_incident)
from india_election_incident
group by State,Incident_Description;

-- Rank states by the frequency of incidents, and rank Lokshabha seats within each state using window functions like RANK() or DENSE_RANK().

select State,Lokshabha_Seat_Name,count(*)as incident_count,dense_rank()over(partition by State order by count(*)desc)as ranked
from india_election_incident
group by State,Lokshabha_Seat_Name;

-- Pivot the data to show a summary of incidents by year and by state. Use Date, State, and Incident_Description.

select extract(year from str_to_date(Date,'%d-%m-%Y'))as year,State,Incident_Description
from india_election_incident
group by year,State;

-- Incidents Before and After a Specific Date
-- Find the number of incidents that occurred before and after the 2024 Lokshabha election date ('08-05-2024') for each state.

select State,count(case when str_to_date(Date,'%d-%m-%Y')>'2024-05-08' then 1 end)as incident_after,
count(case when str_to_date(Date,'%d-%m-%Y')<'2024-05-08' then 1 end)as incident_before
from india_election_incident
group by State;

-- Seasonal Trends in Incidents
-- Identify the months with the highest number of incidents across all states.

with cte as(
select month(str_to_date(Date,'%d-%m-%Y'))as month,State,count(*)as no_of_incident,dense_rank()over(order by count(*)desc)as ranked
from india_election_incident
group by month,State)
select month,State,no_of_incident,ranked
from cte
where ranked=1;

-- Top 3 Lokshabha Seats with Most Incidents
-- Find the top 3 Lokshabha seats in each state with the highest number of incidents.

select State,Lokshabha_Seat_Name,count(*)as incident_count,dense_rank()over(order by count(*)desc)as ranked
from india_election_incident
group by State,Lokshabha_Seat_Name
limit 3;

-- Analysis of Actions Taken
-- Find the percentage of incidents with "Action_taken" recorded for each state.

select State,Action_taken,(count(*)*100)/(select count(*) from india_election_incident)as percent
from india_election_incident
where Action_taken not in ('No action taken')
group by State,Action_taken;

-- Incidents with Multiple Sources
-- Identify incidents reported by more than 3 distinct sources and the states where they occurred.

select Incident_Description,Source_news_article,count(distinct Source_news_article) as count_of_source
from india_election_incident
group by Source_news_article
having count_of_source>1;

-- Incidents by Location
-- Determine which Location_of_Incident within each state had the highest number of incidents.

with cte as(
select State,Location_of_Incident,count(*)as incident_count,dense_rank()over(partition by State order by count(*)desc)as ranked
from india_election_incident
group by State,Location_of_Incident)
select State,Location_of_Incident,incident_count,ranked
from cte
where ranked=1;

-- Incidents with No Action
-- Retrieve a list of incidents where no action was taken despite mentions of critical terms like "violence" or "protest" in the description.

select Incident_Description,Action_taken
from india_election_incident
where Action_taken='No action taken' and Incident_Description like '%Violence%' or Incident_Description like '%Firing%' or Incident_Description like '%Capturing%';

-- Locations with Escalating Incidents
-- Identify locations where the number of incidents increased year-over-year.

with cte as(
select month(str_to_date(Date,'%d-%m-%Y'))as month,State,count(Incident_Description)as current_incident_count,
lag(count(Incident_description))over(order by month(str_to_date(Date,'%d-%m-%Y')))as previous_incident_count
from india_election_incident
group by month,State)
select month,State,current_incident_count,previous_incident_count,(current_incident_count-previous_incident_count)/previous_incident_count*100 as mom_Incident_growth
from cte;

-- Comparison of Action and No-Action States
-- Compare the number of incidents with and without actions for states and rank them based on the difference.

select State,count(case when Action_taken='No action taken' then 1 end)as No_action_taken_count,
count(case when Action_taken in ('Repolling','Voting Station Shutdown','Legal Case','Dismissed by police','Arrested','Dismissed by district Megistrate','Inquiry and no-repolling') then 1 end)as action_taken_count
from india_election_incident
group by State;

-- Incidents During Specific Events
-- Find incidents during critical time periods, such as election months (April and May).

select date_format(str_to_date(Date,'%d-%m-%Y'),'%m')as month,Incident_Description
from india_election_incident
where month(str_to_date(Date,'%d-%m-%Y')) in (4,5);


select * from india_election_incident;