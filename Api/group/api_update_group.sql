drop function if exists api_update_group;
create function api_update_group(usr_id integer, usr_type user_type, json jsonb) returns json
as
$$
declare
    entity_id integer;
    group_name varchar;
    gr_mem group_member;
    update_query text;

    grp user_group;

begin
    entity_id := CAST(jsonb_extract_path_text(json, 'entity_id') AS integer);
    group_name := jsonb_extract_path_text(json, 'name');

    IF group_name IS NULL or length(group_name) > 255 THEN
        return json_build_object('success', false, 'err', '', 'error_field', 'Неправильное название группы');
    end if;

    RAISE NOTICE 'UPDATING GROUP: %', entity_id;

    IF usr_type != 'moderator' THEN
        SELECT * FROM src_get_group_member(usr_id := usr_id, gr_id := entity_id) INTO gr_mem;
        IF gr_mem.user_id IS NULL THEN
            return json_build_object('success', false, 'err', 404);
        end if;
        IF gr_mem.is_creator = FALSE THEN
            return json_build_object('success', false, 'err', 403);
        end if;
    end if;

    SELECT * FROM user_group WHERE group_id = entity_id INTO grp;
    IF grp.group_type = 'personal' OR grp.group_type = 'all' THEN
        return json_build_object('success', false, 'error', 'Редактирование данной группы невозможно');
    end if;

    update_query := ' UPDATE user_group SET name = $1 WHERE group_id = $2 RETURNING group_id';
    EXECUTE update_query USING group_name, entity_id INTO entity_id;
    IF entity_id IS NOT NULL THEN
        return json_build_object('success', true, 'entity_id', entity_id);
    end if;
    return json_build_object('success', false);
end;
$$ language plpgsql;
