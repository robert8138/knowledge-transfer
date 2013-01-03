-- construct the publisher , user_id table
--------------------------------------------------------------------
create local temporary table publisher_user_table
(
	publisher_segment VARCHAR(255),
	user_id BIGINT
)
on commit preserve rows;


-- inserting the publisher, user_id pairs
insert /*+direct*/ into publisher_user_table
select distinct
	content_source_name, user_id
from wapo_fact a 
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr'
where event = 'view_article' and dt between '2012-11-01' and '2012-12-01';


-- inserting the total population , user_id pairs
-- the purpose of this step is for us to get statistics on the population leve
-- when we do readers from each publisher_segment (in publisher_segment_potential_topic_count)
-- and readers for the total population (when calculating readership for each publisher)

insert /*+direct*/ into publisher_user_table
select distinct
	'Total Population', user_id
from wapo_fact a 
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr'
where event = 'view_article' and dt between '2012-11-01' and '2012-12-01';


commit;


-- construct the publisher , topic table
--------------------------------------------------------------------
create local temporary table publisher_topic_table
(
	publisher_segment VARCHAR(255),
	channel_id VARCHAR(100),
	channel_name VARCHAR(100)
)
on commit preserve rows;


-- inserting the publisher, topic pairs
insert /*+direct*/ into publisher_topic_table
select distinct
	content_source_name, channel_id, channel_name
from wapo_fact a 
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr'
where event = 'view_article' and dt between '2012-11-01' and '2012-12-01';


commit;


-- construct the publisher , topic table
--------------------------------------------------------------------
create local temporary table publisher_segment_potential_topic_count_table
(
	publisher_segment VARCHAR(255),
	channel_id VARCHAR(100),
	channel_name VARCHAR(100),
	segment_count BIGINT
)
on commit preserve rows;

insert /*+direct*/ into publisher_segment_potential_topic_count_table
select
	c.publisher_segment,
	a.channel_id,
	a.channel_name,
	count(distinct a.user_id) as segment_count
from wapo_fact a 
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr'
join publisher_user_table c on a.user_id = c.user_id
where event = 'view_article' and dt between '2012-11-01' and '2012-12-01'
group by 1,2,3;


-- compute the readership size for each publisher segment
-- the calculation would also include the total population, since we have
-- a segment name = 'Total population'
--------------------------------------------------------------------

insert /*+direct*/ into publisher_segment_potential_topic_count_table
select
	publisher_segment,
	'Total segment',
	'Total segment',
	count(distinct user_id)
from publisher_user_table
group by 1;

create local temporary table publisher_segment_reach_table
(
	publisher_segment VARCHAR(255),
	channel_id VARCHAR(100),
	channel_name VARCHAR(100),
	segment_count BIGINT,
	reach float
)
on commit preserve rows;

insert /*+direct*/ into publisher_segment_reach_table
select
	publisher_segment,
	channel_id,
	channel_name,
	segment_count,
	cast(segment_count as float)/cast(sum(case when channel_id = 'Total segment' then segment_count else null end) over (partition by publisher_segment) as float) as reach
from publisher_segment_potential_topic_count_table



select
	publisher_segment,
	channel_id,
	channel_name,
	segment_count,
	reach,
	reach/sum(case when publisher_segment = 'Total Population' then reach else null end) over (partition by channel_id, channel_name)*100) as relative_reach
from publisher_segment_reach_table



















