drop function if exists api_update_collection;
create function api_update_collection(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    collection_name varchar;
    grp_id integer;
    grp_member group_member;

    update_query text;
    entity_id integer;
    col collection;
begin
    collection_name := jsonb_extract_path_text(json, 'name');
    entity_id := CAST(jsonb_extract_path(json, 'entity_id') as integer);
    grp_id := src_get_group_by_collection_id(entity_id);

    SELECT * FROM collection WHERE collection_id = entity_id INTO col;

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE or grp_member.is_creator = FALSE and col.creator_id != usr_id THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    update_query := 'UPDATE collection SET name = $1 WHERE collection_id = $2 RETURNING collection_id';
    EXECUTE update_query INTO entity_id USING collection_name, entity_id;

    return '{"success": true, "entity_id": ' || entity_id||'}';
end;
$$ language plpgsql;
