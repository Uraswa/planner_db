drop function if exists src_get_groups;
create function src_get_groups(usr_id integer, perPage integer, page integer)
returns TABLE (group_id integer, name varchar, can_modify boolean)
as
$$
    declare
        offst integer;

begin
    offst := (page - 1) * perPage;
    RETURN QUERY
    SELECT
    gr.group_id as group_id,
    gr.name as name,
    gm.is_creator as can_modify
    FROM user_group gr
    JOIN group_member gm on (gr.group_id = gm.group_id and gm.user_id = usr_id)
    OFFSET offst
    LIMIT perPage;
end;
$$ LANGUAGE plpgsql;
--SELECT * FROM src_get_groups(1, 4, 1);