drop function if exists api_get_group;
create function api_get_group(usr_id integer, usr_type user_type, json jsonb) returns text
as
$$
declare
    grp_id integer;
begin

    grp_id := cast(jsonb_extract_path(json, 'group_id') as integer);

    RETURN (SELECT json_build_object('entity', t) FROM
        (SELECT * FROM src_get_groups(usr_id := usr_id, usr_type := usr_type, perpage := 9999999, page := 1) WHERE group_id = grp_id) as t);

end;
$$ language plpgsql;
SELECT api_get_group(19, 'default','{"group_id":  34}')