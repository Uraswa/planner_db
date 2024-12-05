CREATE EXTENSION IF NOT EXISTS "pgcrypto";

---ПРОВЕРИТЬ ЕСТЬ ЛИ ПОЛЬЗОВАТЕЛЬ В ГРУППЕ
DROP FUNCTION IF EXISTS src_get_group_member;
CREATE OR REPLACE FUNCTION src_get_group_member(
usr_id integer,
gr_id integer) RETURNS group_member as
$$
DECLARE
    gr_member group_member;
BEGIN
    SELECT * INTO gr_member FROM group_member WHERE user_id = usr_id AND group_id = gr_id;
    RETURN gr_member;

end;
$$ LANGUAGE plpgsql;

---ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЯ В ГРУППУ.
DROP FUNCTION IF EXISTS src_add_user_to_group;
CREATE OR REPLACE FUNCTION src_add_user_to_group(usr_id integer, gr_id integer, iscreator boolean, check_group_existance boolean)
    RETURNS result_type AS
$$
DECLARE
    result result_type;
    already_exist_group_member group_member;
BEGIN

    IF check_group_existance = TRUE AND EXISTS(SELECT * FROM user_group WHERE group_id = gr_id) = FALSE THEN
        result.success := FALSE;
        result.error := 'GROUP_NOT_EXIST';
        result.error_field := '';
        RETURN result;
    end if;

    SELECT * FROM src_get_group_member(usr_id, gr_id) INTO already_exist_group_member;
    IF already_exist_group_member.user_id IS NOT NULL THEN
        result.success := FALSE;
        result.error := 'USER_ALREADY_IN_GROUP';
        result.error_field := '';
        RETURN result;
    end if;
    RAISE NOTICE 'INSERTING GROUP MEMBER';
    INSERT INTO group_member (group_id, user_id, is_creator, is_banned) VALUES (gr_id, usr_id, iscreator, false);
    result.success := TRUE;
    result.error := '';
    result.error_field := '';
    RAISE NOTICE 'INSERTED GROUP MEMBER';
    RETURN result;
end;
$$ LANGUAGE plpgsql;

---ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЯ В ГРУППУ ПО ПРИГЛАСИТЕЛЬНОЙ ССЫЛКЕ.
DROP FUNCTION IF EXISTS src_add_user_to_group_by_invitation_link;
CREATE OR REPLACE FUNCTION src_add_user_to_group_by_invitation_link(usr_id integer, inv_link varchar)
    RETURNS result_type AS
$$
DECLARE
    result result_type;
    gr_id boolean;
    get_group_query text;
BEGIN

    get_group_query := 'SELECT group_id FROM user_group WHERE invite_link = $1';
    EXECUTE get_group_query INTO gr_id USING inv_link;

    IF gr_id IS NOT NULL THEN
        result := src_add_user_to_group(usr_id, gr_id, false, false);
        RETURN result;
    end if;

    result.success = FALSE;
    result.error = 'GROUP_NOT_FOUND';
    RETURN result;
end;
$$ LANGUAGE plpgsql;


---СОЗДАТЬ ГРУППУ И ДОБАВИТЬ В ГРУППУ СОЗДАТЕЛЯ ГРУППЫ.
DROP FUNCTION IF EXISTS src_create_group_and_add_user;
CREATE OR REPLACE FUNCTION src_create_group_and_add_user(usr_id integer, name varchar, grouptype group_type)
    RETURNS result_type AS
$$
DECLARE
    invite_link           varchar;
    inserted_group_id     integer;
    result                result_type;
    add_user2group_result result_type;

BEGIN

    IF length(name) > 256 THEN
        result.success := FALSE;
        result.error := 'ERR_GROUP_NAME_TOOLONG';
        result.error_field := 'name';
        RETURN result;
    end if;

    IF grouptype = 'personal' THEN
        IF EXISTS(SELECT *
                  FROM user_group ug
                           JOIN group_member gm ON (gm.user_id = usr_id and gm.group_id = ug.group_id)
                  WHERE ug.group_type = 'personal') THEN
            result.success := FALSE;
            result.error := 'PERSONAL_GROUP_EXISTS';
            RETURN result;
        end if;

    end if;

    IF grouptype = 'all' AND EXISTS(SELECT * FROM user_group WHERE group_type = 'all') THEN
        result.success := FALSE;
        result.error := 'ALL_GROUP_ONLY_ONE';
        RETURN result;
    end if;

    IF grouptype = 'default' THEN
        SELECT * FROM gen_random_uuid() INTO invite_link;

        IF length(name) = 0 THEN
            result.success := FALSE;
            result.error := 'DEFAULT_GROUP_NAME_CANNOTBEEMPTY';
            result.error_field := 'name';
            RETURN result;
        end if;

    ELSE
        invite_link := '';
    end if;

    RAISE NOTICE 'CREATING GROUP ';
    EXECUTE '' ||
            'INSERT INTO user_group (name, group_type, invite_link) ' ||
            'VALUES ($1, $2, $3) RETURNING group_id'
        INTO inserted_group_id USING name, grouptype, invite_link;

    RAISE NOTICE 'ADDING USER % TO GROUP: %', usr_id, inserted_group_id;
    SELECT * INTO add_user2group_result FROM src_add_user_to_group(usr_id, inserted_group_id, true, false);
    add_user2group_result.entity_id := inserted_group_id;
    return add_user2group_result;

END;
$$ LANGUAGE plpgsql;

-- SELECT create_group('test', 'all');
SELECT * FROM src_create_group_and_add_user(1, 'group_name2', 'default');