DROP PROCEDURE IF EXISTS api_create_user_procedure;
CREATE or replace PROCEDURE api_create_user_procedure(input_json jsonb, OUT result jsonb)
LANGUAGE plpgsql
AS $$
DECLARE
    username varchar;
    email varchar;
    password varchar;

    insert_query text;
    inserted_user_id integer;

    add_user_to_all_group_result result_type;
    add_user_to_personal_group_result result_type;

    all_group_id int;
    res result_type;

BEGIN

    res.success := TRUE;
    res.error_field := NULL;
    res.error := NULL;

    username := jsonb_extract_path_text(input_json, 'username');
    email := jsonb_extract_path_text(input_json, 'email');
    password := jsonb_extract_path_text(input_json, 'password');

    IF length(username) > 16 THEN
        result := json_build_object(
            'success', FALSE,
            'error_field', 'username',
            'error', 'Логин пользователя не должен быть больше 16 символов'
        );
        RETURN;
    end if;

    IF length(email) > 256 THEN
         result := json_build_object(
            'success', FALSE,
            'error_field', 'email',
            'error', 'Email не должен быть больше 256 символов'
        );
        RETURN;
    end if;

    IF length(password) > 16 THEN
        result := json_build_object(
            'success', FALSE,
            'error_field', 'password',
            'error', 'Пароль не должен быть больше 16 символов'
        );
        RETURN;
    end if;

    IF check_user_unique(username, email) = FALSE THEN
        result := json_build_object(
            'success', FALSE,
            'error', 'Пользователь с таким логином или email уже существует'
        );
        RAISE NOTICE 'USER IS NOT UNIQUE!';
        RETURN;
    end if;

    password = crypt(password, gen_salt('bf'));
    BEGIN
    insert_query := 'INSERT INTO users (email, username, password) VALUES ($1, $2, $3) RETURNING user_id';
    EXECUTE insert_query INTO inserted_user_id USING email, username, password;

    SELECT group_id INTO all_group_id FROM user_group WHERE group_type = 'all';

    --Теперь добавляем пользоваетеля в группы по умолчанию
    SELECT * INTO add_user_to_all_group_result FROM src_add_user_to_group(inserted_user_id, all_group_id, false, true);
    IF add_user_to_all_group_result.success = FALSE THEN
        RAISE NOTICE 'CANNOT ADD USER TO ALL GROUP';
        res := add_user_to_all_group_result;
        result := json_build_object(
            'success', FALSE,
            'error', 'Не получилось добавить пользователя в общую группу, пожалуйста, поробуйте позже'
        );
        ROLLBACK;
        RETURN;
    end if;

    SELECT * INTO add_user_to_personal_group_result FROM src_create_group_and_add_user(inserted_user_id, 'Личная', 'personal');
    IF add_user_to_personal_group_result.success = FALSE THEN
        RAISE NOTICE 'CANNOT ADD USER TO PERSONAL GROUP';
        res := add_user_to_personal_group_result;
        result := json_build_object(
            'success', FALSE,
            'error', 'Не получилось добавить пользователя в личную группу, пожалуйста, поробуйте позже'
        );
        ROLLBACK;
        RETURN;
    end if;

    res.success := TRUE;
    res.entity_id = inserted_user_id;

    result := json_build_object(
            'success', TRUE,
            'entity_id', inserted_user_id
    );
    COMMIT;
    END;
END;
$$;


-- Вызов процедуры и получение результата
DO $$
DECLARE
    result jsonb;
BEGIN
    -- Вызываем процедуру и получаем результат в переменную result
   call api_create_user_procedure('{"username": "Test user2", "email": "vmzanin2@edu.hse.ru", "password": "test_password123"}', result);
    -- Можно вывести результат для проверки

END;
$$;


