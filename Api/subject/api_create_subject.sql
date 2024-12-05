drop function if exists api_create_subject;
create function api_create_subject(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    subject_name varchar;
    grp_id integer;
    grp_member group_member;

    insert_query text;
    created_entity_id integer;
begin
    subject_name := jsonb_extract_path_text(json, 'name');
    grp_id := (SELECT CAST(jsonb_extract_path_text(json, 'father_entity_id') AS INTEGER));

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    insert_query := 'INSERT INTO subject (group_id, creator_id, name) VALUES ($1, $2, $3) RETURNING subject_id';
    EXECUTE insert_query INTO created_entity_id USING grp_id, usr_id, subject_name;

    return '{"success": true, "entity_id": ' || created_entity_id ||'}';
end;
$$ language plpgsql;
