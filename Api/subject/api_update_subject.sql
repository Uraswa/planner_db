drop function if exists api_update_subject;
create function api_update_subject(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    subject_name varchar;
    grp_id integer;
    grp_member group_member;

    update_query text;
    entity_id integer;
    sub subject;
begin
    subject_name := jsonb_extract_path_text(json, 'name');
    entity_id := CAST(jsonb_extract_path(json, 'entity_id') as integer);
    grp_id := src_get_group_by_subject_id(entity_id);

    SELECT * FROM subject WHERE subject_id = entity_id INTO sub;

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE or grp_member.is_creator = FALSE and sub.creator_id != usr_id THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    update_query := 'UPDATE subject SET name = $1 WHERE subject_id = $2 RETURNING subject_id';
    EXECUTE update_query INTO entity_id USING subject_name, entity_id;

    return '{"success": true, "entity_id": ' || entity_id||'}';
end;
$$ language plpgsql;
