drop function if exists api_get_group_info;
create function api_get_group_info(usr_id int, usr_type user_type, json jsonb) returns json
as
$$
declare
    entity_id int;
    grp_member group_member;
    grp_type group_type;
begin
    entity_id := CAST(jsonb_extract_path_text(json, 'entity_id') AS integer);
    grp_member := src_get_group_member(usr_id := usr_id, gr_id := entity_id);

    IF usr_type != 'moderator' THEN

        IF grp_member.user_id IS NULL or grp_member.is_banned THEN
            return json_build_object('success', false, 'error', 'Ошибка доступа');
        end if;

    end if;

    SELECT group_type INTO grp_type FROM user_group WHERE group_id = entity_id;

    return (SELECT json_build_object(
        'members', (SELECT json_agg(json_build_object(
                    'user_id', grpm.user_id,
                    'user_name', u.username,
                    'is_blocked', grpm.is_banned ,
                    'can_be_kicked', CASE
                        WHEN (grpm.is_creator or usr_type = 'moderator') and grp_type = 'default' THEN TRUE
                        ELSE FALSE END
                    ))

                        FROM group_member grpm
                        JOIN users u ON (u.user_id = grpm.user_id)
                        WHERE group_id = entity_id),
        'can_kick', CASE WHEN grp_member.is_creator OR usr_type = 'moderator' THEN TRUE ELSE FALSE END
        ));

end;
$$ language plpgsql;
SELECT * FROM api_get_group_info(26, 'default', '{"entity_id":  54}')