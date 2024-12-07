drop function if exists api_get_daily_plan;
create function api_get_daily_plan(usr_id integer, usr_type user_type, json jsonb) RETURNS jsonb
as
$$
    declare
        task_row RECORD;
        max_diff_to_repeat INT := 10;
        current_diff_to_repeat INT := 0;
        max_diff_to_learn INT := 5;
        current_diff_to_learn INT := 0;
        result_tasks jsonb[] := '{}';
begin
    -- КВОТА ДЛЯ НОВЫХ ЗАДАНИЙ
    FOR task_row IN SELECT
        t.task_id,
        t.name as task_name,
        t.description,
        c.name as collection_name,
        s.name as subject_name,
        ut.difficulty,
        false as is_repeating
           FROM task t
    JOIN collection c on t.collection_id = c.collection_id
    JOIN collection_subscriber cs on c.collection_id = cs.collection_id and cs.user_id = usr_id
    JOIN subject s on c.subject_id = s.subject_id
    JOIN group_member gm  on gm.user_id = usr_id and gm.group_id = s.group_id and gm.is_banned = FALSE
    JOIN user_task ut on ut.task_id = t.task_id and ut.is_creator = TRUE
    LEFT JOIN user_task utcur on utcur.task_id = t.task_id and utcur.user_id = usr_id
    WHERE utcur.user_id IS NULL
    LIMIT 10
    LOOP
        IF current_diff_to_learn + task_row.difficulty <= max_diff_to_learn THEN

            result_tasks := result_tasks || to_jsonb(task_row);

            current_diff_to_learn := current_diff_to_learn + task_row.difficulty;
        end if;
    end loop;


    -- КВОТА ДЛЯ ПОВТОРЕНИЯ
    FOR task_row IN SELECT
                        ut.task_id,
                        ut.difficulty,
                        t.name as task_name,
                        t.description,
                        c.name as collection_name,
                        s.name as subject_name,
                        ri.interval_id,
                        ri.rule,
                        ut.last_repeat_date,
                        true as is_repeating
                    FROM user_task ut
             JOIN task t on ut.task_id = t.task_id
             JOIN collection c on c.collection_id = t.collection_id
             JOIN collection_subscriber cs on c.collection_id = cs.collection_id and cs.user_id = usr_id
             JOIN subject s on c.subject_id = s.subject_id
             JOIN repeat_interval ri on ri.interval_id = ut.repeat_interval
             WHERE ut.user_id = usr_id and ut.is_blocked = FALSE and ut.next_repeat_date < NOW()
             ORDER BY ut.next_repeat_date ASC, ut.difficulty ASC
             LIMIT 10
    LOOP
        IF current_diff_to_repeat + task_row.difficulty <= max_diff_to_repeat THEN

            result_tasks := result_tasks || to_jsonb(task_row);

            current_diff_to_repeat := current_diff_to_repeat + task_row.difficulty;
        end if;
    end loop;

    RETURN (SELECT json_build_object(
        'tasks', (SELECT jsonb_agg(elem) FROM unnest(result_tasks) AS elem),
        'intervals', (SELECT json_agg(i) FROM repeat_interval i WHERE i.creator_id = usr_id or i.interval_id = 0)
        ));
end;
$$ language plpgsql;
SELECT * FROM api_get_daily_plan(26, 'moderator', '{}')