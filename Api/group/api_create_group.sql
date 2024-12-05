drop function if exists api_create_group;
create function api_create_group(usr_id integer,  usr_type user_type, json jsonb) returns json
as
$$
declare
    group_name varchar;
    group_create_res result_type;
    new_invitation_link varchar;
begin
    group_name := jsonb_extract_path_text(json, 'name');
    RAISE NOTICE 'GROUP_NAME: %', group_name;
    SELECT * FROM src_create_group_and_add_user(usr_id, group_name, 'default') INTO group_create_res;

    IF group_create_res.success = TRUE THEN
        SELECT invite_link INTO new_invitation_link FROM user_group WHERE group_id = group_create_res.entity_id;
        return json_build_object('success', group_create_res.success,
        'entity_id', group_create_res.entity_id,
        'error', group_create_res.error,
            'invite_link', new_invitation_link
            );
    end if;

    return json_build_object('success', group_create_res.success,
        'entity_id', group_create_res.entity_id,
        'error', group_create_res.error);
end;
$$ language plpgsql;
