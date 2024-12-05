drop function if exists api_create_comment;
create function api_create_comment(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare

    comment_text text;
    solution_id integer;
    grp_id integer;
    grp_member group_member;

    insert_query text;
    created_entity_id integer;
begin
    comment_text := jsonb_extract_path_text(json, 'text');
    solution_id := CAST(jsonb_extract_path(json, 'father_entity_id') AS integer);
    RAISE NOTICE 'solution ID %', solution_id;
    grp_id := src_get_group_by_solution_id(solution_id);

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    insert_query := 'INSERT INTO comment (solution_id, creator_id, text) VALUES ($1, $2, $3) RETURNING comment_id';
    EXECUTE insert_query INTO created_entity_id USING solution_id, usr_id, comment_text;

    return '{"success": true, "entity_id": ' || created_entity_id ||'}';
end;
$$ language plpgsql;
