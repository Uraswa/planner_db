drop function if exists api_delete_collection;
create function api_delete_collection(usr_id integer, usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    entity_id integer;

    grp_member group_member;
    grp_id integer;
begin

    entity_id := (SELECT CAST(jsonb_extract_path_text(json, 'entity_id') AS INTEGER));

    grp_id := src_get_group_by_collection_id(entity_id);

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF usr_type != 'moderator' AND (grp_member.user_id IS NULL or grp_member.is_banned = TRUE) THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    if usr_type = 'moderator' or grp_member.is_creator = TRUE THEN
        DELETE FROM collection col WHERE col.collection_id = entity_id RETURNING col.collection_id INTO entity_id;
    else
        DELETE FROM collection col WHERE col.collection_id = entity_id AND col.creator_id = usr_id RETURNING col.collection_id INTO entity_id;
    end if;

    IF entity_id IS NULL THEN
        return json_build_object('success', FALSE);
    end if;

    return json_build_object('success', TRUE, 'entity_id', entity_id);
end;
$$ language plpgsql;
