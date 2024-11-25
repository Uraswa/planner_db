DROP FUNCTION IF EXISTS api_login;
CREATE or replace FUNCTION api_login(input_json jsonb)
RETURNS TABLE (user_id integer, username varchar, user_type user_type)
AS $$
DECLARE
    name varchar;
    passw varchar;

BEGIN
    name := jsonb_extract_path_text(input_json, 'username');
    passw := jsonb_extract_path(input_json, 'password');

    passw := md5(passw);
    RETURN QUERY SELECT u.user_id, u.username, u.user_type FROM users u WHERE u.password = passw and u.username = name;

END;
$$ LANGUAGE plpgsql;
--SELECT * from api_login('{"username":"my_nickname", "password": "13456"}')

