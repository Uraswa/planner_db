drop function if exists api_get_user_info;
create function api_get_user_info(usr_id integer, usr_type user_type) returns text
as
$$
declare
    res text;
begin
     SELECT json_build_object(
        'username', u.username,
        'user_id', u.user_id,
        'user_type', u.user_type,
        'is_banned', u.is_blocked
        ) FROM users u WHERE u.user_id = usr_id INTO res;
     return res;
end;
$$ language plpgsql;
SELECT api_get_user_info(19, 'moderator');