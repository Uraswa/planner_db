drop function if exists src_get_tasks;
create function src_get_tasks(usr_id integer, col_id integer, perPage integer, page integer)
returns TABLE (task_id integer, name varchar, description text, can_modify boolean)
as
$$
    declare
        offst integer;

begin
    offst := (page - 1) * perPage;
    RETURN QUERY
    SELECT
    ts.task_id as task_id,
    ts.name as name,
    ts.description as description,
    (gm.is_creator or u2t.user_id IS NOT NULL AND u2t.is_creator) as can_modify
    FROM task ts
    JOIN collection col ON (col.collection_id = ts.collection_id)
    JOIN subject sb ON col.subject_id = sb.subject_id
    JOIN user_group gr on (gr.group_id = sb.group_id)
    JOIN group_member gm on (gr.group_id = gm.group_id and gm.user_id = usr_id)
    LEFT JOIN user_task u2t ON (u2t.task_id = ts.task_id and u2t.user_id = usr_id)
    WHERE ts.collection_id = col_id
    OFFSET offst
    LIMIT perPage;
end;
$$ LANGUAGE plpgsql;