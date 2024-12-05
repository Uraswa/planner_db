drop function if exists api_update_task;
create function api_update_task(usr_id integer, usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    task_name varchar;
    task_description text;
    grp_id integer;
    grp_member group_member;

    update_query text;
    entity_id integer;
    tas user_task;
begin
    task_name := jsonb_extract_path_text(json, 'name');
    task_description := jsonb_extract_path_text(json, 'description');
    entity_id := CAST(jsonb_extract_path(json, 'entity_id') as integer);
    grp_id := src_get_group_by_task_id(entity_id);

    SELECT * FROM user_task WHERE task_id = entity_id and user_id = usr_id INTO tas;

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE or grp_member.is_creator = FALSE and tas.is_creator = FALSE THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    update_query := 'UPDATE task SET name = $1, description = $2 WHERE task_id = $3 RETURNING task_id';
    EXECUTE update_query INTO entity_id USING task_name, task_description, entity_id;

    return '{"success": true, "entity_id": ' || entity_id||'}';
end;
$$ language plpgsql;
