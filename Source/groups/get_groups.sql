drop function if exists src_get_groups;
create function src_get_groups(usr_id integer, usr_type user_type, perPage integer, page integer)
returns TABLE (group_id integer, name varchar, can_modify boolean, grp_type group_type, invite_link varchar)
as
$$
    declare
        offst integer;

begin
    offst := (page - 1) * perPage;

     IF usr_type = 'moderator' THEN
        RETURN QUERY
        SELECT
        gr.group_id as group_id,
        gr.name as name,
        TRUE as can_modify,
        gr.group_type,
        gr.invite_link
        FROM user_group gr
        OFFSET offst
        LIMIT perPage;
    else
        RETURN QUERY
        SELECT
        gr.group_id as group_id,
        gr.name as name,
        gm.is_creator as can_modify,
        gr.group_type,
        gr.invite_link
        FROM user_group gr
        JOIN group_member gm on (gr.group_id = gm.group_id and gm.user_id = usr_id)
        OFFSET offst
        LIMIT perPage;
    end if;
end;
$$ LANGUAGE plpgsql;
SELECT * FROM src_get_groups(1, 'moderator',4, 1);