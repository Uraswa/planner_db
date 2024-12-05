drop function if exists src_get_subjects;
create function src_get_subjects(usr_id integer, usr_type user_type, grp_id integer, perPage integer, page integer)
returns TABLE (subject_id integer, name varchar, can_modify boolean)
as
$$
    declare
        offst integer;

begin
    offst := (page - 1) * perPage;


    RETURN QUERY
    SELECT
    sb.subject_id as subject_id,
    sb.name as name,
    (gm.is_creator OR sb.creator_id = usr_id) as can_modify
    FROM subject sb
    JOIN user_group gr on (gr.group_id = sb.group_id)
    JOIN group_member gm on (gr.group_id = gm.group_id and gm.user_id = usr_id)
    WHERE sb.group_id = grp_id
    OFFSET offst
    LIMIT perPage;
end;
$$ LANGUAGE plpgsql;