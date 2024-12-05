drop function if exists api_create_task;
create function api_create_task(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    task_name varchar;
    task_description text;
    collection_id integer;
    grp_id integer;
    grp_member group_member;

    insert_query text;
    created_entity_id integer;
begin
    task_name := jsonb_extract_path_text(json, 'name');
    task_description := jsonb_extract_path_text(json, 'description');
    collection_id := CAST(jsonb_extract_path(json, 'father_entity_id') AS integer);
    RAISE NOTICE 'collection ID %', collection_id;
    grp_id := src_get_group_by_collection_id(collection_id);

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    insert_query := 'INSERT INTO task (collection_id, name, description) VALUES ($1, $2, $3) RETURNING task_id';
    EXECUTE insert_query INTO created_entity_id USING collection_id, task_name, task_description;

    INSERT INTO user_task (task_id, user_id, is_creator, difficulty, next_repeat_date) VALUES (created_entity_id, usr_id, TRUE, 1, NOW());

    return '{"success": true, "entity_id": ' || created_entity_id ||'}';
end;
$$ language plpgsql;
