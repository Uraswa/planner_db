drop function if exists api_subscribe_collection;
create function api_subscribe_collection(usr_id integer, usr_type user_type, json jsonb) returns json
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

    INSERT INTO collection_subscriber (collection_id, user_id, subscription_date)
    VALUES (col_id, usr_id, now())
    ON CONFLICT(collection_id, user_id) DO NOTHING;
    return '{"success": true}';
end;
$$ language plpgsql;
