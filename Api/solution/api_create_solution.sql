drop function if exists api_create_solution;
create function api_create_solution(usr_id integer,  usr_type user_type, json jsonb) returns jsonb
as
$$
declare

    solut text;
    task_id integer;
    grp_id integer;
    grp_member group_member;

    insert_query text;
    created_entity_id integer;
begin
    solut := jsonb_extract_path_text(json, 'solution');
    task_id := CAST(jsonb_extract_path(json, 'father_entity_id') AS integer);
    RAISE NOTICE 'task ID %', task_id;
    grp_id := src_get_group_by_task_id(task_id);

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF grp_member.user_id IS NULL or grp_member.is_banned = TRUE THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    insert_query := 'INSERT INTO solution (task_id, creator_id, solution) VALUES ($1, $2, $3) RETURNING solution_id';
    EXECUTE insert_query INTO created_entity_id USING task_id, usr_id, solut;

    return '{"success": true, "entity_id": ' || created_entity_id ||'}';
end;
$$ language plpgsql;
