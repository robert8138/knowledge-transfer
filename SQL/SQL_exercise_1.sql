-- Using analytic function to calculate percentages
-- Refer to Vertica SQL documentation
-- Analytics function would be truncate rows, it will return the same number results as the original row_dim
select
	read_ct,
	count_users,
	cast(count_users as float)/cast(sum(count_users) over () as float) as percentage_users
from (
	select 
		read_ct,
		count(*) as count_users
	from (
		select
			user_id,
			count(*) as read_ct
		from wapo_fact a
		join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr' and dt = '2012-12-01'
		where event = 'view_article' 
		group by user_id ) temp
	group by read_ct
	order by read_ct ) temp_2
order by read_ct;



-- computing rolling averages
select
	content_source_name,
	dt,
	read_ct,
	avg(read_ct) over (partition by content_source_name order by dt rows between 6 preceding and current row) as rolling_avg
	-- avg(read_ct) over (partition by content_source_name order by dt rows between unbounded preceding and current row) as rolling_avg
	-- avg(read_ct) over (partition by content_source_name order by dt rows between unbounded preceding and unbounded following) as rolling_avg
from (
select
	content_source_name,
	dt,
	count(*) as read_ct
from wapo_fact a
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr' 
where event = 'view_article' and dt between '2012-09-01' and '2012-12-01'
group by 1,2
order by 1,2 ) temp
order by content_source_name, dt;



-- first value example
-- look at the first publisher read from the user
select distinct
	user_id,
	first_value(content_source_name) over (partition by user_id order by eventtime rows between unbounded preceding and unbounded following) as first_publisher_read 
	-- first_value(content_source_name ignore nulls) over (partition by user_id order by eventtime rows between unbounded preceding and unbounded following) as first_publisher_read 
from wapo_fact a
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr' 
where event = 'view_article' and dt = '2012-09-01';


-- row_number()
-- first 5 actions of each user
select
	user_id,
	event,
	row_num
from (
	select
		user_id,
		event,
		row_number() over (partition by user_id order by eventtime) as row_num
	from wapo_fact a
	join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr' 
	where dt = '2012-09-01' ) temp
where row_num <= 5
limit 100;


-- conditional_true_event
-- label the visit number (if visit time gap >= 30 secs, then increment the visit num count)
select
	user_id,
	to_timestamp(eventtime/1000) at timezone 'EST5EDT',
	event,
	conditional_true_event(eventtime - lag(eventtime) >= 1800000) over (partition by user_id order by eventtime) as visit_num
from wapo_fact a
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr' 
where dt = '2012-09-01'
order by 1,2
limit 100;


-- conditional_true_event
-- helpful for making new ids (usually use row_number() or conditional_true_event)
-- the problem with the previous approach is that each user would get a 0th, 1st...etc visit
-- you want to make these identifiers unique so that you can apply analytics function [partition on users again]
-- this is an example that teach you how to solve that problem.
select
	user_id,
	readable_time,
	visit_num,
	conditional_true_event(visit_num != lag(visit_num) or (user_id != lag(user_id))) over (order by user_id, readable_time) as unique_visit_num
from (
	select
		user_id,
		to_timestamp(eventtime/1000) at timezone 'EST5EDT' as readable_time,
		event,
		conditional_true_event(eventtime - lag(eventtime) >= 1800000) over (partition by user_id order by eventtime) as visit_num
	from wapo_fact a
	join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr' 
	where dt = '2012-09-01'
	order by 1,2 ) temp
limit 100;


-- check to see SQL connections
select * from v_monitor.sessions;

-- check existing permanent tables
select * fro tables;

-- unrelated to SQL
-- There is also the analytics.wapolabs.com website, changing the wordpress, including new links...etc.