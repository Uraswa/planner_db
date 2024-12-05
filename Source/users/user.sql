DROP FUNCTION IF EXISTS check_user_unique;
CREATE OR REPLACE FUNCTION check_user_unique(username varchar, email varchar)
RETURNS BOOLEAN
AS $$
    DECLARE
        check_query text;
        res BOOLEAN;
    BEGIN
        check_query := 'SELECT EXISTS(SELECT * FROM users WHERE username = $1 or email = $1)';
        EXECUTE check_query INTO res USING  username, email;
        RETURN res = FALSE;
    end;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS src_get_user_by_ud;
CREATE OR REPLACE FUNCTION src_get_user_by_ud(usr_id integer)
RETURNS users
AS $$
    declare
        usr users;
    BEGIN
        SELECT * FROM users WHERE user_id = usr_id INTO usr;
        return usr;
    end;
$$ LANGUAGE plpgsql;

SELECT src_get_user_by_ud(19);