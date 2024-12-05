drop function if exists api_get_task;
create function api_get_task(usr_id integer, usr_type user_type, json jsonb) returns json
as
$$
declare
    t_id integer;
    grp_id integer;
    grp_member group_member;

    res text;

begin

    t_id := cast(jsonb_extract_path(json, 'task_id') as integer);
    grp_id := src_get_group_by_task_id(t_id);

    grp_member := src_get_group_member(usr_id := usr_id, gr_id := grp_id);
    IF usr_type != 'moderator' AND (grp_member.user_id IS NULL or grp_member.is_banned = TRUE) THEN
        return '{"success": false, "error": "Ошибка доступа"}';
    end if;

    RAISE NOTICE '%', grp_id;

    SELECT
                json_build_object(
                        'entity_id', t.task_id,
                        'name', t.name,
                        'description', t.description,
                        'can_modify', grp_member.is_creator or ut.is_creator,
                        'can_delete', CASE WHEN usr_type = 'moderator' THEN TRUE ELSE grp_member.is_creator or ut.is_creator END,
                        'creator_name', creator.username,
                        'solutions', (
                            SELECT
                                json_agg(
                                json_build_object(
                                    'entity_id', s.solution_id,
                                    'solution', s.solution,
                                    'can_modify', s.can_modify,
                                    'can_delete', CASE WHEN usr_type = 'moderator' THEN TRUE ELSE s.can_modify END,
                                    'comments', (SELECT json_agg(json_build_object(
                                                    'entity_id', c.comment_id,
                                                    'text', c.text,
                                                    'can_modify', c.can_modify,
                                                    'can_delete',  CASE WHEN usr_type = 'moderator' THEN TRUE ELSE s.can_modify END
                                                ))
                                                 FROM src_get_comments(usr_id := usr_id, solut_id := s.solution_id, perpage := 99999, page := 1) as c)
                                ))
                            FROM src_get_solutions(usr_id := usr_id, usr_type := usr_type, ts_id := t.task_id, perpage := 99999, page := 1) as s)
                       )
            FROM task t
            LEFT JOIN public.user_task ut on t.task_id = ut.task_id and ut.user_id = usr_id
            LEFT JOIN user_task u2t2 on u2t2.task_id = t.task_id and u2t2.is_creator = true
            LEFT JOIN users creator on u2t2.user_id = creator.user_id
            WHERE t.task_id = t_id INTO res;

    RETURN res;
end;
$$ language plpgsql;
SELECT api_get_task(19, 'default','{"task_id":  1}')