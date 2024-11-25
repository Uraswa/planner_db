drop function if exists src_get_group;
create function src_get_subjects(usr_id integer, grp_id integer, perPage integer, page integer)
returns TABLE (subject_id integer, name varchar, can_modify boolean)
as
$$
    declare
        offst integer;

begin
    offst := (page - 1) * perPage;

    IF perPage = 0 THEN
        offst := 0;
        perPage := 2147483647;
    end if;

    RETURN QUERY
    SELECT
    sb.subject_id as subject_id,
    sb.name as name,
    (gr.can_modify OR sb.creator_id = usr_id) as can_modify
    FROM src_get_groups(usr_id := usr_id, perpage := 0, page := 0) gr
    JOIN subject sb ON (sb.group_id = gr.group_id)
    WHERE sb.group_id = grp_id
    OFFSET offst
    LIMIT perPage;
end;
$$ LANGUAGE plpgsql;