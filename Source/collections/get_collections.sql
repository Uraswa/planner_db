drop function if exists src_get_collections;
create function src_get_collections(usr_id integer, sb_id integer, perPage integer, page integer)
returns TABLE (collection_id integer, name varchar, can_modify boolean)
as
$$
    declare
        offst integer;

begin
    offst := (page - 1) * perPage;

    SELECT
    col.collection_id as collection_id,
    col.name as name,
    (gm.is_creator or col.creator_id) as can_modify
    FROM collection col
    JOIN subject sb ON col.subject_id = sb.subject_id
    JOIN user_group gr on (gr.group_id = sb.group_id)
    JOIN group_member gm on (gr.group_id = gm.group_id and gm.user_id = usr_id)
    WHERE col.subject_id = sb_id
    OFFSET offst
    LIMIT perPage;
end;
$$ LANGUAGE plpgsql;