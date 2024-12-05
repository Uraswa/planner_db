drop function if exists api_unsubscribe_collection;
create function api_unsubscribe_collection(usr_id integer, usr_type user_type, json jsonb) returns json
as
$$
declare
    col_id integer;
    grp_id integer;
    grp_member group_member;

begin

    col_id := cast(jsonb_extract_path(json, 'collection_id') as integer);
    grp_id := src_get_group_by_collection_id(col_id);

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    DELETE FROM collection_subscriber WHERE collection_id = col_id and user_id = usr_id RETURNING collection_id INTO col_id;
    IF col_id IS NULL THEN
        return '{"success": false}';
    end if;
    return '{"success": true}';
end;
$$ language plpgsql;
