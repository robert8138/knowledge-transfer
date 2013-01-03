-- This SQL script produce the necessary SQL calculations for the social tab of the publisher report


-- keep track of the status of the script
----------------------------------------------------------------------------------------------------
create local temporary table script_run_details
(
	script_name varchar(100),
	script_parameters varchar(255),
	script_start_time timestamptz
)
on commit preserve rows;

insert /*+direct*/ into script_run_details
select
	'publisher_report_social.sql',
	':dt=' || :dt,
	now();

commit;

insert /*+direct*/ into tableau_script_status
select
	script_name,
	script_parameters,
	script_start_time,
	now(),
	1,
	'Script started'
from script_run_details;

commit;



-- There are four statistics that we want to keep track of
-- 1. shares from frontpage article teaser.
-- 2. shares from full article page.
-- 3. tweets from full article page.
-- 4. facebook comments from full article page.
----------------------------------------------------------------------------------------------------
create local temporary table social_stats_table
(
	dt Date,
	content_title VARCHAR(255),
	content_source_name VARCHAR(255),
	shares_frontpage_teaser BIGINT,
	shares_full_article_page BIGINT,
	tweets_full_article_page BIGINT,
	fb_comments_full_article_page BIGINT,
	article_visit_count BIGINT
)
on commit preserve rows;

insert /*+direct*/ into social_stats_table
select
	dt,
	content_title,
	content_source_name,
	sum(case when event = 'share_content' and module like '%full_channel%' then 1 else 0 end) as shares_frontpage_teaser,
	sum(case when event = 'share_content' and module like '%article_tools%' then 1 else 0 end) as shares_full_article_page,
	sum(case when event = 'tweet_content' and module like '%article_tools%' then 1 else 0 end) as tweets_full_article_page,
	sum(case when event = 'send_content' and module like '%article_tools%' then 1 else 0 end) as send_full_article_page,
	--#sum(case when event = 'fb_comment_create' and module = 'f' then 1 else 0 end) as fb_comments_full_article_page,
	sum(case when event = 'view_article' then 1 else 0 end) as article_visit_count
from wapo_fact a
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr'
group by 1,2,3
order by 1,2,3;

commit;


create local temporary table fb_comments_table
(
	dt Date,
	content_title VARCHAR(255),
	content_source_name VARCHAR(255),
	comments BIGINT
)
on commit preserve rows;


insert /*+direct*/ into fb_comments_table
select
	dt,
	content_title,
	content_source_name,
	sum(comments)
from wpsr_article_social
group by 1,2,3
order by 1,2,3;

commit;


-- remove data from today that is not needed
-- make sure you are not deleting data that were written from other scripts
delete from wapo_entity_agg_dev
where dt = :dt and script = 'publisher_report_social.sql';


-- insert the data into wapo_entity_agg_dev
-- make sure the column attributes are aligned
insert /*+direct*/ into wapo_entity_agg_dev
select
	'publisher_report_social.sql' as script,
	dt as dt,
	null as last_visit_dt,
	'day' as period,
	dt as start_dt,
	dt as end_dt,
	1 as segment_id,
	'wpsr' as entity_id,
	'Washington Post Social Reader' as entity_name,
	'WaPo::Washington Post Social Reader' as full_entity_name,
	2 as entity_level_id,
	'Publisher Report: social' as hier,
	0 as level_id,
	'Publisher' as h1_id,
	content_source_name as h1, 
	null as h2_id,
	null as h2,
	null as h3_id,
	null as h3,
	'Article title' as h4_id,
	content_title as h4,
	null as h5_id,
	null as h5,
	null as h6_id,
	null as h6,
	null as h7_id,
	null as h7,
	null as h8_id,
	null as h8,
	null as h9_id,
	null as h9,
	null as h10_id,
	null as h10,
	'activity' as metric_category,
	'shares_from_frontpage' as metric_name,
	'count of shares from articles on frontpage' as metric_description,
	shares_frontpage_teaser as value 
from social_stats_table;

----------------------------------------------------------------------------------------------------
insert /*+direct*/ into wapo_entity_agg_dev
select
	'publisher_report_social.sql' as script,
	dt as dt,
	null as last_visit_dt,
	'day' as period,
	dt as start_dt,
	dt as end_dt,
	1 as segment_id,
	'wpsr' as entity_id,
	'Washington Post Social Reader' as entity_name,
	'WaPo::Washington Post Social Reader' as full_entity_name,
	2 as entity_level_id,
	'Publisher Report: social' as hier,
	0 as level_id,
	'Publisher' as h1_id,
	content_source_name as h1, 
	null as h2_id,
	null as h2,
	null as h3_id,
	null as h3,
	'Article title' as h4_id,
	content_title as h4,
	null as h5_id,
	null as h5,
	null as h6_id,
	null as h6,
	null as h7_id,
	null as h7,
	null as h8_id,
	null as h8,
	null as h9_id,
	null as h9,
	null as h10_id,
	null as h10,
	'activity' as metric_category,
	'shares_from_articles' as metric_name,
	'count of shares from individual article pages' as metric_description,
	shares_full_article_page as value 
from social_stats_table;

----------------------------------------------------------------------------------------------------
insert /*+direct*/ into wapo_entity_agg_dev
select
	'publisher_report_social.sql' as script,
	dt as dt,
	null as last_visit_dt,
	'day' as period,
	dt as start_dt,
	dt as end_dt,
	1 as segment_id,
	'wpsr' as entity_id,
	'Washington Post Social Reader' as entity_name,
	'WaPo::Washington Post Social Reader' as full_entity_name,
	2 as entity_level_id,
	'Publisher Report: social' as hier,
	0 as level_id,
	'Publisher' as h1_id,
	content_source_name as h1, 
	null as h2_id,
	null as h2,
	null as h3_id,
	null as h3,
	'Article title' as h4_id,
	content_title as h4,
	null as h5_id,
	null as h5,
	null as h6_id,
	null as h6,
	null as h7_id,
	null as h7,
	null as h8_id,
	null as h8,
	null as h9_id,
	null as h9,
	null as h10_id,
	null as h10,
	'activity' as metric_category,
	'shares_from_tweets' as metric_name,
	'count of tweet shares from individual article pages' as metric_description,
	tweets_full_article_page as value 
from social_stats_table;

----------------------------------------------------------------------------------------------------
insert /*+direct*/ into wapo_entity_agg_dev
select
	'publisher_report_social.sql' as script,
	dt as dt,
	null as last_visit_dt,
	'day' as period,
	dt as start_dt,
	dt as end_dt,
	1 as segment_id,
	'wpsr' as entity_id,
	'Washington Post Social Reader' as entity_name,
	'WaPo::Washington Post Social Reader' as full_entity_name,
	2 as entity_level_id,
	'Publisher Report: social' as hier,
	0 as level_id,
	'Publisher' as h1_id,
	content_source_name as h1, 
	null as h2_id,
	null as h2,
	null as h3_id,
	null as h3,
	'Article title' as h4_id,
	content_title as h4,
	null as h5_id,
	null as h5,
	null as h6_id,
	null as h6,
	null as h7_id,
	null as h7,
	null as h8_id,
	null as h8,
	null as h9_id,
	null as h9,
	null as h10_id,
	null as h10,
	'activity' as metric_category,
	'sends_from_full_article_page' as metric_name,
	'count of sends from individual article pages' as metric_description,
	tweets_full_article_page as value 
from social_stats_table;

----------------------------------------------------------------------------------------------------
insert /*+direct*/ into wapo_entity_agg_dev
select
	'publisher_report_social.sql' as script,
	dt as dt,
	null as last_visit_dt,
	'day' as period,
	dt as start_dt,
	dt as end_dt,
	1 as segment_id,
	'wpsr' as entity_id,
	'Washington Post Social Reader' as entity_name,
	'WaPo::Washington Post Social Reader' as full_entity_name,
	2 as entity_level_id,
	'Publisher Report: social' as hier,
	0 as level_id,
	'Publisher' as h1_id,
	content_source_name as h1, 
	null as h2_id,
	null as h2,
	null as h3_id,
	null as h3,
	'Article title' as h4_id,
	content_title as h4,
	null as h5_id,
	null as h5,
	null as h6_id,
	null as h6,
	null as h7_id,
	null as h7,
	null as h8_id,
	null as h8,
	null as h9_id,
	null as h9,
	null as h10_id,
	null as h10,
	'activity' as metric_category,
	'shares_fb_comments' as metric_name,
	'count of fb comments from individual article pages' as metric_description,
	comments as value 
from fb_comments_table;


----------------------------------------------------------------------------------------------------
insert /*+direct*/ into wapo_entity_agg_dev
select
	'publisher_report_social.sql' as script,
	dt as dt,
	null as last_visit_dt,
	'day' as period,
	dt as start_dt,
	dt as end_dt,
	1 as segment_id,
	'wpsr' as entity_id,
	'Washington Post Social Reader' as entity_name,
	'WaPo::Washington Post Social Reader' as full_entity_name,
	2 as entity_level_id,
	'Publisher Report: social' as hier,
	0 as level_id,
	'Publisher' as h1_id,
	content_source_name as h1, 
	null as h2_id,
	null as h2,
	null as h3_id,
	null as h3,
	'Article title' as h4_id,
	content_title as h4,
	null as h5_id,
	null as h5,
	null as h6_id,
	null as h6,
	null as h7_id,
	null as h7,
	null as h8_id,
	null as h8,
	null as h9_id,
	null as h9,
	null as h10_id,
	null as h10,
	'activity' as metric_category,
	'article_views' as metric_name,
	'count of article views' as metric_description,
	article_visit_count as value 
from social_stats_table;


commit;


-- when the the script run is complete
-- log the completion information
----------------------------------------------------------------------------------------------------
insert /*+direct*/ into tableau_script_status
select
	script_name,
	script_parameters,
	script_start_time,
	now(),
	2,
	'Script finished'
from script_run_details;

commit;