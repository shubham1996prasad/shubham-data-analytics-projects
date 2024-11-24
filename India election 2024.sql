use india_election;

-- what is the total seats

select count(distinct Parliament_Constituency) from constituencywise_result;

-- Question: Retrieve constituencies where the margin of victory is less than 1,000 votes, along with the leading and trailing candidates and their parties.

select constituencywise_result.Constituency_Name,constituencywise_result.Margin,statewise_result.Leading_Candidate,statewise_result.Trailing_Candidate,
Partywise_result.Party
from constituencywise_result join statewise_result 
on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
join partywise_result on constituencywise_result.Party_ID=partywise_result.Party_ID
where constituencywise_result.Margin<10000;

-- Question: Find the top candidate (with the highest EVM votes) in each constituency, including their party and total votes. 

with cte as(
select constituencywise_details.Candidate as candidate,constituencywise_result.Constituency_Name as constituency,partywise_result.Party as party,
sum(constituencywise_details.Total_Votes)as total_votes,sum(constituencywise_details.EVM_Votes)as heighest_evm,
dense_rank()over(partition by constituencywise_result.Constituency_Name order by sum(constituencywise_details.EVM_Votes)desc)as ranked
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID
join partywise_result on constituencywise_result.Party_ID=partywise_result.Party_ID
group by constituencywise_details.Candidate,constituencywise_result.Constituency_Name)
select candidate,constituency,party,total_votes,heighest_evm,ranked
from cte
where ranked=1;

-- Question: List each party's total and average number of postal votes received across all constituencies.

select partywise_result.Party,constituencywise_result.Constituency_Name,sum(constituencywise_details.Postal_Votes)as total_postal_votes,
avg(constituencywise_details.Postal_Votes)as avg_postal_votes
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_Id
join partywise_result on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party,constituencywise_result.Constituency_Name;

-- Question: Display the constituencies where any single candidate secured more than 60% of the total votes.

select constituencywise_result.Constituency_Name,constituencywise_details.Candidate,constituencywise_details.Percent_of_Votes
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID
where constituencywise_details.Percent_of_Votes>55;

-- Question: Retrieve the winning candidates' vote percentages for each constituency.

select constituencywise_result.Constituency_Name,constituencywise_result.Winning_Candidate,constituencywise_details.Percent_of_Votes
from constituencywise_result join constituencywise_details
on constituencywise_result.Constituency_ID=constituencywise_result.Constituency_ID
group by constituencywise_result.Constituency_Name;

-- Question: Count the number of constituencies won by each party in each state.

select state.State,partywise_result.Party,count(constituencywise_result.Constituency_ID)as total_constituency_won
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
join statewise_result on statewise_result.Parliament_Constituency=constituencywise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by state.State,partywise_result.Party
order by total_constituency_won desc;

-- Question: Calculate the average margin of victory for each party across all constituencies.

select partywise_result.Party,constituencywise_result.Constituency_Name,avg(constituencywise_result.Margin)as avg_margin
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party
order by avg_margin desc;

-- Question: List the top 5 constituencies with the highest margin of victory, including the winning candidate, party, and total votes.

select constituencywise_result.constituency_Name,sum(constituencywise_result.Margin)as heighest_margin,sum(constituencywise_result.Total_Votes)as total_votes,
constituencywise_result.Winning_Candidate,partywise_result.Party
from constituencywise_result join partywise_result
on constituencywise_result.party_ID=partywise_result.Party_ID
group by constituencywise_result.constituency_Name
order by heighest_margin desc
limit 5;

-- Question: Display the total votes won by each party in each parliament constituency.

select partywise_result.Party,constituencywise_result.Constituency_Name,sum(constituencywise_result.Total_Votes)as total_votes
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party,constituencywise_result.Constituency_Name
order by total_votes desc;

-- Question: Retrieve the list of winning candidates who received the highest number of postal votes in their constituencies, along with their party.

select constituencywise_result.Winning_Candidate,constituencywise_result.Constituency_Name,
partywise_result.Party,sum(constituencywise_details.Postal_Votes)as heighest_postal_votes
from constituencywise_result join constituencywise_details
on constituencywise_result.Constituency_ID=constituencywise_details.Constituency_Id
join partywise_result on constituencywise_result.Party_ID=partywise_result.Party_ID
group by constituencywise_result.Winning_Candidate
order by heighest_postal_votes desc;

-- Question: Show the leading and trailing candidates for each constituency in every state.

select state.State,constituencywise_result.Constituency_Name,statewise_result.Leading_Candidate,statewise_result.Trailing_Candidate
from statewise_result join constituencywise_result on statewise_result.Parliament_Constituency=constituencywise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by state.State,constituencywise_result.Constituency_Name;

-- Question: Find the party that has won the most constituencies within a particular state.

with cte as(
select state.State as state,partywise_result.Party as party,count(constituencywise_result.Constituency_ID)as count_of_constituency,
dense_rank()over(partition by state.State order by count(constituencywise_result.Constituency_ID)desc)as ranked
from partywise_result join constituencywise_result
on partywise_result.Party_ID=constituencywise_result.Party_ID
join statewise_result on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by state.State,partywise_result.Party)
select state,Party,count_of_constituency,ranked
from cte
where ranked=1;

-- Question: Retrieve the list of constituencies where two or more candidates have an equal number of votes.

SELECT cd.Constituency_ID, cd.Candidate, cd.Total_Votes
FROM constituencywise_details cd
WHERE cd.Total_Votes IN (
    SELECT Total_Votes 
    FROM constituencywise_details 
    WHERE Constituency_ID = cd.Constituency_ID
    GROUP BY Total_Votes
    HAVING COUNT(*) > 1
);

-- Write a query to find the top 5 constituencies with the highest voter turnout based on Total_Votes.

select constituencywise_result.Constituency_Name,sum(Total_Votes)as total_votes,dense_rank()over(order by sum(Total_Votes)desc)as ranked
from constituencywise_result
group by constituencywise_result.Constituency_Name
limit 5;

-- Query to find constituencies where the margin of victory was less than 5% of the total votes

with cte as(
select Constituency_Name,Margin,Total_Votes,(Margin/Total_Votes)*100 as Margin_percentage
from constituencywise_result)
select Constituency_Name,Margin,Total_Votes,Margin_percentage
from cte
where Margin_percentage<5;

-- Find the constituency with the highest percentage of postal votes.

select constituencywise_result.Constituency_Name,(constituencywise_details.Postal_Votes/constituencywise_details.Total_Votes)*100 as percent_postalvotes
from constituencywise_result join constituencywise_details
on constituencywise_result.Constituency_ID=constituencywise_details.Constituency_ID
order by percent_postalvotes desc;

-- Write a query to list the parties with the highest number of wins in each state.

with cte as(
select state.State as state,partywise_result.Party as party,count(constituencywise_result.Constituency_ID)as count,
dense_rank()over(partition by state.State order by count(constituencywise_result.Constituency_ID)desc)as ranked
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
join statewise_result on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by state.State,partywise_result.Party)
select state,Party,count,ranked
from cte
where ranked=1;

-- Determine which party had the most candidates participating across all constituencies.

select partywise_result.Party,constituencywise_result.Constituency_Name,count(constituencywise_details.Candidate) as count_candidate
from constituencywise_result join constituencywise_details
on constituencywise_result.Constituency_ID=constituencywise_details.Constituency_ID
join partywise_result on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party;

-- Write a query to find the party with the highest average margin of victory across all constituencies.

select partywise_result.Party,constituencywise_result.Constituency_Name,avg(constituencywise_result.Margin)as avg_margin
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party
order by avg_margin desc;

-- List the top 10 candidates with the highest percentage of votes in their constituencies.

select constituencywise_details.Candidate,constituencywise_result.Constituency_Name,max(constituencywise_details.Percent_of_Votes)as heighest_percent_votes
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID
group by constituencywise_details.Candidate
order by heighest_percent_votes desc
limit 10;

-- Write a query to find candidates who won by the smallest margin.

select constituencywise_details.Candidate,constituencywise_result.Winning_Candidate,min(constituencywise_result.Margin)as smallest_margin
from constituencywise_result join constituencywise_details
on constituencywise_result.Constituency_ID=constituencywise_details.Constituency_ID
where constituencywise_details.Candidate=constituencywise_result.Winning_Candidate
group by constituencywise_details.Candidate
order by smallest_margin asc;

-- Determine the total votes obtained by the winning candidates for each party.

select partywise_result.Party,constituencywise_result.Winning_Candidate,sum(constituencywise_result.Total_Votes)
over(partition by partywise_result.Party order by sum(constituencywise_result.Total_Votes)desc)as total_votes
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party,constituencywise_result.Winning_Candidate;

-- Write a query to calculate the total number of votes cast per state.

select state.State,sum(constituencywise_result.Total_Votes)as total_votes
from constituencywise_result join statewise_result
on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by total_votes
order by total_votes desc;

-- Find the state with the highest average margin of victory across its constituencies.

select state.State,constituencywise_result.Constituency_Name,avg(constituencywise_result.Margin)as heighest_avg_margin
from constituencywise_result join statewise_result 
on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by state.State,constituencywise_result.Constituency_Name
order by heighest_avg_margin desc;

-- Get the number of constituencies won by each party in each state.

select state.State,partywise_result.Party,count(constituencywise_result.Constituency_ID)
over(partition by state.State order by count(constituencywise_result.Constituency_ID)desc)as count_of_countituency
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
join statewise_result on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by state.State,partywise_result.Party;


-- Write a query to list constituencies where the leading and trailing candidates belong to the same party.





-- Determine constituencies where the margin between the leading and trailing candidates is more than 300,000 votes.

select statewise_result.Constituency,statewise_result.Leading_Candidate,statewise_result.Trailing_Candidate,statewise_result.Margin
from statewise_result
where statewise_result.Margin>300000;

-- Identify the top 3 constituencies with the closest competition (smallest margin) and their leading and trailing candidates.

select constituencywise_result.Constituency_Name,statewise_result.Leading_Candidate,
statewise_result.Trailing_Candidate,min(constituencywise_result.Margin)as smallest_margin
from constituencywise_result join statewise_result
on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
group by constituencywise_result.Constituency_Name
order by smallest_margin asc
limit 5;

-- Write a query to check if any party won all constituencies in a given state.




-- Calculate the percentage of total votes each party received across all constituencies.

select partywise_result.Party,constituencywise_result.Constituency_Name,constituencywise_details.Percent_of_Votes
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID
join partywise_result on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party;

-- Write a query to find the average margin for winning candidates grouped by party.

select partywise_result.Party,constituencywise_result.Winning_candidate,avg(constituencywise_result.Margin)as avg_margin 
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party;

-- Determine the percentage of constituencies won by each party in each state.

select state.State,partywise_result.Party,(count(*)*100)/(select count(*) from constituencywise_result)as percent
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
join statewise_result on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by state.State,partywise_result.Party;

-- Write a query to find the winning candidate’s party name for each constituency.

select partywise_result.Party,constituencywise_result.Constituency_Name,constituencywise_result.Winning_Candidate
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID;

-- Generate a report showing the performance of each party in each state, including total wins, total votes, and average margin.

select state.State,partywise_result.Party,sum(partywise_result.Won)as total_won,sum(constituencywise_result.Total_Votes)as total_votes,
avg(constituencywise_result.Margin)as avg_margin
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
join statewise_result on constituencywise_result.Parliament_Constituency=statewise_result.Parliament_Constituency
join state on statewise_result.State_ID=state.State_ID
group by state.State,partywise_result.Party;

-- Find the total number of constituencies contested by each party, and the number of wins and losses for each.

select partywise_result.Party,count(constituencywise_result.Constituency_ID)as total_constituency,sum(partywise_result.Won)as total_win
from constituencywise_result join partywise_result
on constituencywise_result.Party_ID=partywise_result.Party_ID
group by partywise_result.Party;

-- Determine how many constituencies were won due to postal votes, meaning the winning margin was smaller than the number of postal votes.

select count(constituencywise_details.Constituency_ID)as count
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID
where constituencywise_result.Margin<constituencywise_details.Postal_Votes;

-- Write a query to calculate the percentage of constituencies where postal votes exceeded 10% of total votes.

with cte as(
select constituencywise_result.Constituency_Name as constituency_name,(constituencywise_details.Postal_Votes/constituencywise_details.Total_Votes*100) as percent
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID)
select constituency_Name,percent
from cte
where percent>10;

-- Find the top 3 candidates who received the highest number of postal votes.

select constituencywise_details.Candidate,sum(Postal_Votes)as heighest_postalvotes,dense_rank()over(order by sum(Postal_Votes)desc)as ranked
from constituencywise_details
group by Candidate
limit 3;

-- Write a query to list all the constituencies where the winning candidate received more than 60% of the total votes.

select constituencywise_result.Constituency_Name,constituencywise_result.Winning_Candidate,constituencywise_details.Percent_of_Votes
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID
where constituencywise_details.Percent_of_Votes>55;

-- Find constituencies where no candidate received more than 50% of the total votes.

select constituencywise_result.Constituency_Name,constituencywise_details.Candidate,constituencywise_details.Percent_of_Votes
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID
where constituencywise_details.Percent_of_Votes <=50;

-- Determine the average Percent_of_Votes received by winning candidates across all constituencies.

select constituencywise_result.Constituency_Name,constituencywise_result.Winning_Candidate,round(avg(constituencywise_details.Percent_of_Votes),2)as avg_percentvotes
from constituencywise_details join constituencywise_result
on constituencywise_details.Constituency_ID=constituencywise_result.Constituency_ID
group by constituencywise_result.Constituency_Name,constituencywise_result.Winning_Candidate;
 


SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
select * from constituencywise_details;
select * from constituencywise_result;
select * from partywise_result;
select * from state;
select * from statewise_result;