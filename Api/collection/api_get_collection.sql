drop function if exists api_get_collection;
create function api_get_collection(usr_id integer, usr_type user_type, json jsonb) returns text
as
$$
declare
    col_id integer;
    grp_id integer;
    grp_member group_member;

    res text;

begin

    col_id := cast(jsonb_extract_path(json, 'collection_id') as integer);
    grp_id := src_get_group_by_collection_id(col_id);

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF usr_type != 'moderator' AND (grp_member.user_id IS NULL or grp_member.is_banned = TRUE) THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    RAISE NOTICE '%', grp_id;

    SELECT
                json_build_object(
                        'collection_id', col.collection_id,
                        'name', col.name,
                        'can_modify', CASE WHEN col.creator_id = usr_id THEN TRUE ELSE FALSE END,
                        'is_subscribed', EXISTS(SELECT * FROM collection_subscriber cs WHERE cs.collection_id = col.collection_id AND cs.user_id = usr_id)
                    )
            FROM collection col WHERE col.collection_id = col_id INTO res;

    RETURN res;
end;
$$ language plpgsql;
SELECT api_get_collection(19, 'default','{"collection_id":  3}')