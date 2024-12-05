drop function if exists api_update_solution;
create function api_update_solution(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare
    solution_desc varchar;
    grp_id integer;
    grp_member group_member;

    update_query text;
    entity_id integer;
    sol solution;
begin
    solution_desc := jsonb_extract_path_text(json, 'solution');
    entity_id := CAST(jsonb_extract_path(json, 'entity_id') as integer);
    grp_id := src_get_group_by_solution_id(entity_id);

    SELECT * FROM solution WHERE solution_id = entity_id INTO sol;

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE or grp_member.is_creator = FALSE and sol.creator_id != usr_id THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    update_query := 'UPDATE solution SET solution = $1 WHERE solution_id = $2 RETURNING solution_id';
    EXECUTE update_query INTO entity_id USING solution_desc, entity_id;

    return '{"success": true, "entity_id": ' || entity_id||'}';
end;
$$ language plpgsql;
