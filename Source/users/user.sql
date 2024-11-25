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