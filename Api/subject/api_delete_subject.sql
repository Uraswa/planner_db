drop function if exists api_delete_subject;
create function api_delete_subject(usr_id integer, usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    entity_id integer;

    grp_member group_member;
    sub subject;
begin

    entity_id := (SELECT CAST(jsonb_extract_path_text(json, 'entity_id') AS INTEGER));

    SELECT * FROM subject s WHERE  s.subject_id = entity_id INTO sub;
    IF sub.subject_id IS NULL THEN
        return '{"success": false, "error": "Не найден"}';
    end if;

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := sub.group_id);
    IF usr_type != 'moderator' AND (grp_member.user_id IS NULL or grp_member.is_banned = TRUE) THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    if usr_type = 'moderator' or grp_member.is_creator = TRUE THEN
        DELETE FROM subject s WHERE s.subject_id = entity_id RETURNING s.subject_id INTO entity_id;
    else
        DELETE FROM subject s WHERE s.subject_id = entity_id AND s.creator_id = usr_id RETURNING s.subject_id INTO entity_id;
    end if;

    IF entity_id IS NULL THEN
        return json_build_object('success', FALSE);
    end if;

    return json_build_object('success', TRUE, 'entity_id', entity_id);
end;
$$ language plpgsql;
