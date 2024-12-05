drop function if exists api_create_collection;
create function api_create_collection(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    collection_name varchar;
    subject_id integer;
    grp_id integer;
    grp_member group_member;

    insert_query text;
    created_entity_id integer;
begin
    collection_name := jsonb_extract_path_text(json, 'name');
    subject_id := CAST(jsonb_extract_path(json, 'father_entity_id') AS integer);
    RAISE NOTICE 'SUBJECT ID %', subject_id;
    grp_id := src_get_group_by_subject_id(subject_id);

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    insert_query := 'INSERT INTO collection (subject_id, creator_id, name) VALUES ($1, $2, $3) RETURNING collection_id';
    EXECUTE insert_query INTO created_entity_id USING subject_id, usr_id, collection_name;

    return '{"success": true, "entity_id": ' || created_entity_id ||'}';
end;
$$ language plpgsql;
