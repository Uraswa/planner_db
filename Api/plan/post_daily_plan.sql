drop procedure if exists post_daily_plan;
create procedure post_daily_plan(usr_id int, usr_type user_type, json jsonb, OUT result jsonb )
as
$$
declare
    task_row jsonb;
    current_task_id integer;
    current_task_difficulty integer;
    current_task_remember integer;
    current_task_interval_id integer;
    grp INTEGER;
    grp_member group_member;

    next_repeat_index int;
    ut user_task;
    current_interval repeat_interval;

    res result_type;

begin

    res.success := true;
    BEGIN
    FOR task_row IN SELECT * FROM jsonb_array_elements(json)
    LOOP
        current_task_difficulty := CAST(jsonb_extract_path(task_row, 'difficulty') AS integer);

        IF current_task_difficulty < 1 OR current_task_difficulty > 5 THEN
            res.success := false;
            res.error := 'Сложность должна быть в пределах от 1 до 5';
            EXIT;
        end if;


        IF jsonb_extract_path(task_row, 'remember') IS NOT NULL THEN
            current_task_remember := CAST(jsonb_extract_path(task_row, 'remember') AS integer);
        end if;

        current_task_id := CAST(jsonb_extract_path(task_row, 'task_id') AS integer);
        current_task_interval_id := CAST(jsonb_extract_path(task_row, 'interval_id') AS integer);
        RAISE NOTICE '%', current_task_difficulty;
        RAISE NOTICE '%', current_task_id;
        RAISE NOTICE '%', current_task_interval_id;


        grp := src_get_group_by_task_id(current_task_id);

        IF grp IS NULL THEN
            res.success := false;
            res.error := 'Группа не существует';
            EXIT;
        end if;

        grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp);
        IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE THEN
            res.success := false;
            res.error := 'Ошибка доступа';
            EXIT;
        end if;

        SELECT * INTO current_interval FROM repeat_interval WHERE interval_id = current_task_interval_id;
        IF current_interval.interval_id IS NULL THEN
            res.success := false;
            res.error := 'Интервал повторения не найден';
            EXIT;
        end if;

        SELECT * INTO ut FROM user_task  WHERE user_id = usr_id AND task_id = current_task_id;

        IF ut.user_id IS NOT NULL THEN

            IF current_task_remember IS NULL or current_task_remember = 0 THEN
                next_repeat_index := CAST(regexp_replace(current_interval.index_if_failure, 'i=(\d)', '\1') AS INTEGER);
            ELSE
                next_repeat_index := ut.repeat_index + 1;
            end if;

            UPDATE user_task SET
                                 last_repeat_date = NOW(),
                                 next_repeat_date = src_calculate_next_repeat_data(next_repeat_index, current_interval.rule),
                                 repeat_interval = current_task_interval_id,
                                 repeat_index = next_repeat_index,
                                 difficulty = current_task_difficulty
                                 WHERE task_id = current_task_id AND user_id = usr_id;


        ELSE

            IF exists(SELECT task_id FROM task WHERE task_id = current_task_id) = FALSE THEN
                res.success := false;
                res.error := 'Задача ' || current_task_id::varchar || ' не существует';
                EXIT;
            end if;

            INSERT INTO user_task (
                                   task_id,
                                   user_id,
                                   is_creator,
                                   difficulty,
                                   repeat_interval,
                                   is_blocked,
                                   repeat_index,
                                   last_repeat_date,
                                   next_repeat_date)
            VALUES (
                     current_task_id,
                    usr_id,
                    FALSE,
                    current_task_difficulty,
                    current_task_interval_id,
                    FALSE,
                    0,
                    NOW(),
                    src_calculate_next_repeat_data(0, current_interval.rule)
            );
        end if;


    end loop;


    IF res.success = FALSE THEN
        ROLLBACK;
    ELSE
        COMMIT;
    end if;

    END;

    result := json_build_object('success', res.success, 'error', res.error, 'error_field', res.error_field);

    RAISE NOTICE '%', res.success;

end;
$$ language plpgsql;



