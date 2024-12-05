drop function if exists api_delete_group;
create function api_delete_group(usr_id integer, usr_type user_type, json jsonb) returns json
as
$$
declare
    entity_id integer;
    gr_mem group_member;
    grp user_group;

begin
    entity_id := CAST(jsonb_extract_path_text(json, 'entity_id') AS integer);
    RAISE NOTICE 'DELETING GROUP: %', entity_id;

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
        return json_build_object('success', false, 'error', 'Удаление данной группы невозможно');
    end if;

    DELETE FROM user_group g WHERE g.group_id = entity_id RETURNING g.group_id INTO entity_id;
    IF entity_id IS NOT NULL THEN
        return json_build_object('success', true);
    end if;
    return json_build_object('success', false);
end;
$$ language plpgsql;
