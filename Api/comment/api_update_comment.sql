drop function if exists api_update_comment;
create function api_update_comment(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    comment_text varchar;
    grp_id integer;
    grp_member group_member;

    update_query text;
    entity_id integer;
    com comment;
begin
    comment_text := jsonb_extract_path_text(json, 'text');
    entity_id := CAST(jsonb_extract_path(json, 'entity_id') as integer);
    grp_id := src_get_group_by_comment_id(entity_id);

    SELECT * FROM comment WHERE comment_id = entity_id INTO com;

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE or com.creator_id != usr_id THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    update_query := 'UPDATE comment SET text = $1 WHERE comment_id = $2 RETURNING comment_id';
    EXECUTE update_query INTO entity_id USING comment_text, entity_id;

    return '{"success": true, "entity_id": ' || entity_id||'}';
end;
$$ language plpgsql;
