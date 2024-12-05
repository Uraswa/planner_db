drop function if exists api_exit_from_group;
create function api_exit_from_group(usr_id integer, usr_type user_type, json jsonb) returns json
as
$$
declare
    entity_id integer;
    gr_mem    group_member;
    grp user_group;
begin
    entity_id := CAST(jsonb_extract_path_text(json, 'entity_id') AS integer);
    RAISE NOTICE 'USER % EXITING FROM GROUP: %', usr_id, entity_id;

    SELECT * FROM src_get_group_member(usr_id := usr_id, gr_id := entity_id) INTO gr_mem;
    IF gr_mem.user_id IS NULL THEN
        return json_build_object('success', false, 'err', 404);
    end if;

    SELECT * FROM user_group WHERE group_id = entity_id INTO grp;
    IF grp.group_type = 'personal' OR grp.group_type = 'all' THEN
        return json_build_object('success', false, 'error', 'Выход из данной группы невозможен');
    end if;

    DELETE FROM group_member g WHERE g.group_id = entity_id AND g.user_id = usr_id RETURNING g.group_id INTO entity_id;
    IF entity_id IS NOT NULL THEN
        return json_build_object('success', true, 'entity_id', entity_id);
    end if;
    return json_build_object('success', false);
end;
$$ language plpgsql;
