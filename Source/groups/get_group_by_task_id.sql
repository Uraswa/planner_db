drop function if exists src_get_group_by_task_id;
create function src_get_group_by_task_id(tas_id integer)
returns integer
as
$$
    declare
        res integer;

begin
    SELECT gr.group_id
        FROM task t
        JOIN collection c on (c.collection_id = t.collection_id)
        JOIN subject s on (s.subject_id = c.subject_id)
        JOIN user_group gr on s.group_id = gr.group_id
                    where t.task_id = tas_id  INTO res;
    return res;
end;
$$ LANGUAGE plpgsql;
SELECT src_get_group_by_task_id(1)