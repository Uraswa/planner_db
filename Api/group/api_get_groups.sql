drop function if exists api_get_groups;
create function api_get_groups(usr_id integer, usr_type user_type, json jsonb) returns json
as
$$
begin

    RETURN (SELECT json_agg(json_build_object(
        'entity_id', g.group_id,
        'name', g.name,
        'can_modify', g.can_modify,
        'can_delete', CASE WHEN usr_type = 'moderator' THEN TRUE ELSE g.can_modify END,
        'group_type', g.grp_type,
        'invite_link', g.invite_link,
        'subjects', (SELECT json_agg(
                        json_build_object(
                            'entity_id', s.subject_id,
                            'name', s.name,
                            'can_modify', s.can_modify,
                            'can_delete', CASE WHEN usr_type = 'moderator' THEN TRUE ELSE s.can_modify END,
                            'collections', (SELECT json_agg(
                                                json_build_object(
                                                    'entity_id', c.collection_id,
                                                    'name', c.name,
                                                    'is_subscribed', CASE WHEN cs.user_id IS NOT NULL THEN TRUE ELSE FALSE END,
                                                    'can_modify', c.can_modify,
                                                    'can_delete', CASE WHEN usr_type = 'moderator' THEN TRUE ELSE c.can_modify END,
                                                    'tasks', (SELECT json_agg(
                                                        json_build_object(
                                                            'entity_id', t.task_id,
                                                            'name', t.name,
                                                            'description', t.description,
                                                            'creator_name', t.creator_name
                                                        )
                                                        ) FROM src_get_tasks(usr_id := usr_id, usr_type := usr_type, col_id := c.collection_id, perpage := 99999, page := 1) as t)
                                                )
                                            )
                                            FROM src_get_collections(usr_id := usr_id, usr_type := usr_type, sb_id := s.subject_id, perpage := 99999, page := 1) as c
                                            LEFT JOIN collection_subscriber cs on (cs.collection_id = c.collection_id and cs.user_id = usr_id)
                                            )
                        )
                     )
                     FROM src_get_subjects(usr_id := usr_id, usr_type := usr_type, grp_id := g.group_id, perpage := 99999, page := 1) as s)


               ))
    FROM  src_get_groups(usr_id := usr_id, usr_type := usr_type, perpage := 999999, page := 1) as g);

end;
$$ language plpgsql;
SELECT api_get_groups(19, 'default','{}')