--
-- Queries to compare 2 wordpress database
-- This is useful to simulate/reproduce production settings in staging environment
--
-- ########################################################
-- @author: Guillaume Diaz
-- @Version 1.0 - 2020/08
-- @Since 2020/08
-- ########################################################
-- Production database:         qindiaz.baby_*
-- Local database (staging):    wordpress.wp_*
--

-- Compare options
select babyoptions.option_name, babyoptions.option_value as 'prod value', wpoptions.option_value as 'default value'
from qindiaz.baby_options as babyoptions
    left join wordpress.wp_options as wpoptions on babyoptions.option_name = wpoptions.option_name
order by babyoptions.option_name;

select babymeta.meta_key, babymeta.meta_value as 'prod value', wpmeta.meta_value as 'default value'
from qindiaz.baby_usermeta as babymeta
    left join wordpress.wp_usermeta as wpmeta on babymeta.meta_key = wpmeta.meta_key
order by babymeta.meta_key;



select * from qindiaz.baby_options where option_name like 'hide_my_site%';
select * from wordpress.wp_options where option_name like 'hide_my_site%';


select babyoptions.option_name, babyoptions.option_value as 'prod value', wpoptions.option_value as 'default value'
from qindiaz.baby_options as babyoptions
    left join wordpress.wp_options as wpoptions on babyoptions.option_name = wpoptions.option_name
where babyoptions.option_value != wpoptions.option_value
order by babyoptions.option_name;

select babyoptions.option_name, babyoptions.option_value as 'prod value', wpoptions.option_value as 'default value'
from qindiaz.baby_options as babyoptions
    left join wordpress.wp_options as wpoptions on babyoptions.option_name = wpoptions.option_name
where (
    (wpoptions.option_value is null)
   OR (babyoptions.option_value != wpoptions.option_value)
    )
order by babyoptions.option_name;