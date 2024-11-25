DROP FUNCTION IF EXISTS create_user;
CREATE or replace FUNCTION create_user(input_json jsonb)
RETURNS result_type
AS $$
DECLARE
    username varchar;
    email varchar;
    password varchar;

    insert_query text;
    inserted_user_id integer;

    add_user_to_all_group_result result_type;
    add_user_to_personal_group_result result_type;

    res result_type;
BEGIN
    username := jsonb_extract_path_text(input_json, 'username');
    email := jsonb_extract_path_text(input_json, 'email');
    password := jsonb_extract_path_text(input_json, 'password');

    IF length(username) > 16 THEN
        res.success := FALSE;
        res.error_field := 'username';
        res.error := 'PASSWORD_MAX_SIZE';
        RETURN res;
    end if;

    IF length(email) > 256 THEN
        res.success := FALSE;
        res.error_field := 'email';
        res.error := 'EMAIL_MAX_SIZE';
        RETURN res;
    end if;

    IF length(password) > 16 THEN
        res.success := FALSE;
        res.error_field := 'password';
        res.error := 'PASSWORD_MAX_SIZE';
        RETURN res;
    end if;

    IF check_user_unique(username, email) = FALSE THEN
        RAISE NOTICE 'USER IS NOT UNIQUE!';
        res.success := FALSE;
        res.error_field := 'username or email';
        res.error := 'USER IS NOT UNIQUE!';
        RETURN res;
    end if;

    password = md5(password);
    insert_query := 'INSERT INTO users (email, username, password) VALUES ($1, $2, $3) RETURNING user_id';
    EXECUTE insert_query INTO inserted_user_id USING email, username, password;

    --Теперь добавляем пользоваетеля в группы по умолчанию
    SELECT * INTO add_user_to_all_group_result FROM add_user_to_group(inserted_user_id, 1, false, true);
    IF add_user_to_all_group_result.success = FALSE THEN
        RAISE NOTICE 'CANNOT ADD USER TO ALL GROUP';
        res := add_user_to_all_group_result;
        RETURN res;
    end if;

    SELECT * INTO add_user_to_personal_group_result FROM create_group_and_add_user(inserted_user_id, '', 'personal');
    IF add_user_to_personal_group_result.success = FALSE THEN
        RAISE NOTICE 'CANNOT ADD USER TO PERSONAL GROUP';
        res := add_user_to_personal_group_result;
        RETURN res;
    end if;

    res.success := TRUE;
    return res;
END;
$$ LANGUAGE plpgsql;


