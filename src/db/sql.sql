select
    `t`.*,
    'aaa',
    `c`.*
from `information_schema`.`tables` as `t` join `information_schema`.`columns` as `c` on `t`.`table_schema` = `c`.`table_schema` and `t`.`table_name` = `c`.`table_name`
where `t`.`table_schema` = 'tmc'
order by `t`.`table_name`;


select
    `t`.`table_name`,
    `create_time`,
    `table_collation`,
    `table_comment`,
    `column_name`,
    `column_default`,
    `is_nullable`,
    `data_type`,
    `column_type`,
    `column_key`,
    `extra`,
    `column_comment`,
    `collation_name`
from `information_schema`.`tables` as `t` join `information_schema`.`columns` as `c` on `t`.`table_schema` = `c`.`table_schema` and `t`.`table_name` = `c`.`table_name`
where `t`.`table_schema` = 'tmc'
order by `t`.`table_name`