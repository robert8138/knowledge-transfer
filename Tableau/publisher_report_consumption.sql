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


-- keep track of device usage information
----------------------------------------------------------------------------------------------------
create local temporary table device_usage_table
(
	dt Date,
	device VARCHAR(255),
	content_source_name VARCHAR(255),
	usage_count BIGINT
)
on commit preserve rows;

insert /*+direct*/ into device_usage_table
select
	dt,
	device,
	content_source_name,
	count(*) as usage_count
from wapo_fact a
join wapo_product_hier b on a.product_id = b.product_id and b.entity_id = 'wpsr'
group by 1,2,3
order by 1,2,3;



----------------------------------------------------------------------------------------------------
insert /*+direct*/ into wapo_entity_agg_dev
select
	'publisher_report_consumption.sql' as script,
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
	'Publisher Report: consumption' as hier,
	0 as level_id,
	'Publisher' as h1_id,
	content_source_name as h1, 
	'device' h2_id,
	device as h2,
	null as h3_id,
	null as h3,
	null as h4_id,
	null as h4,
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
	'device usage' as metric_name,
	'count of usages from a particular device' as metric_description,
	usage_count as value 
from device_usage_table;


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

