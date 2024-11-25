drop function if exists src_get_solutions;
create function src_get_solutions(usr_id integer, ts_id integer, perPage integer, page integer)
returns TABLE (solution_id integer, solution text, can_modify boolean)
as
$$
    declare
        offst integer;

begin
    offst := (page - 1) * perPage;
    RETURN QUERY
    SELECT
    s.solution_id as solution_id,
    s.solution as description,
    (gm.is_creator or s.creator_id = usr_id) as can_modify
    FROM solution s
    JOIN task ts ON (ts.task_id = s.task_id)
    JOIN collection col ON (col.collection_id = ts.collection_id)
    JOIN subject sb ON col.subject_id = sb.subject_id
    JOIN user_group gr on (gr.group_id = sb.group_id)
    JOIN group_member gm on (gr.group_id = gm.group_id and gm.user_id = usr_id)
    WHERE s.task_id = ts_id
    OFFSET offst
    LIMIT perPage;
end;
$$ LANGUAGE plpgsql;