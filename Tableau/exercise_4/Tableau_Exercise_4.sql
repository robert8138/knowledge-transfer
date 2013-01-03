-- This SQL script produce the necessary SQL calculations for the article entry point report
-- Only the final output table should be permanent, all other tables should be temporary
-- otherwise re-run/refresh would break because those table already exist.


-- create a wapo_entity_agg_dev table that has the same dimension as wapo_entity_agg
-- This is a convenient hack, because then you do not have to type the column definitions
-- for each column. This table is use for development only.

-- select * into wapo_entity_agg_dev
-- from wapo_entity_agg
-- where 1 = 2;


-- keep track of the status of the script
-- log the starting point of the script run

create local temporary table script_run_details
(
	script_name varchar(100),
	script_parameters varchar(255),
	script_start_time timestamptz
)
on commit preserve rows;

insert /*+direct*/ into script_run_details
select
	'article_entryPoint.sql',
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

-- now create the necessary temp table for updating the tables
-- only numeric needs to specified precision
create local temporary table publisher_entryPoint_table
(
	dt Date,
	ref_category VARCHAR(63),
	ref_name VARCHAR(122),
	source_label VARCHAR(100),
	medium_label VARCHAR(100),
	location_label VARCHAR(100),
	simple_desc_label VARCHAR(255),
	content_title VARCHAR(255),
	content_source_name VARCHAR(255),
	value BIGINT
)
on commit preserve rows;


insert /*+direct*/ into publisher_entryPoint_table
select
	dt,
	ref_category,
	ref_name,
	source_label,
	medium_label,
	location_label,
	simple_desc_label,
	content_title,
	content_source_name,
	count(*) as value
from wapo_fact a
join wapo_entry_dim b on a.entry_id = b.entry_id
join wapo_product_hier c on a.product_id = c.product_id and c.entity_id = 'wpsr'
where event = 'view_article' and dt = :dt
group by 1,2,3,4,5,6,7,8,9;

commit;

-- remove data from today that is not needed
-- make sure you are not deleting data that were written from other scripts
delete from wapo_entity_agg_dev
where dt = :dt and script = 'article_entryPoint.sql';


-- insert the data into wapo_entity_agg_dev
-- make sure the column attributes are aligned
insert /*+direct*/ into wapo_entity_agg_dev
select
	'article_entryPoint.sql' as script,
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
	'Publisher Entry Point' as hier,
	0 as level_id,
	'Publisher' as h1_id,
	content_source_name as h1, 
	'ref_category' as h2_id,
	ref_category as h2,
	'ref_name' as h3_id,
	ref_name as h3,
	'Article title' as h4_id,
	content_title as h4,
	'source_label' as h5_id,
	source_label as h5,
	'medium_label' as h6_id,
	medium_label as h6,
	'location_label' as h7_id,
	location_label as h7,
	'simple_desc_label' as h8_id,
	simple_desc_label as h8,
	null as h9_id,
	null as h9,
	null as h10_id,
	null as h10,
	'activity' as metric_category,
	'article_pageviews' as metric_name,
	'count of article pageviews' as metric_description,
	value as value 
from publisher_entryPoint_table;

commit;



-- complete the script run and log the information
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


-- giving permission to Tableau for a newly created table
-- grant select on wapo_entity_agg_dev to tableau;
