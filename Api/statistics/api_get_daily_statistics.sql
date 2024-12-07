drop function if exists api_get_daily_statistics;
create function api_get_daily_statistics(usr_id integer, usr_type user_type, json jsonb) returns jsonb
as
$$
begin

    RETURN (SELECT json_agg(json_build_object('cnt',s.cnt, 'total_difficulty', s.total_difficulty))
                        FROM (SELECT count(*) AS cnt, SUM(ut.difficulty) as total_difficulty FROM history h
                        JOIN user_task ut on (ut.task_id = h.task_id and ut.user_id = usr_id)
                        WHERE h.user_id = usr_id
                        GROUP BY h.date) as s);
end;
$$ language plpgsql;
SELECT * FROM api_get_daily_statistics(35, 'default', '{}');