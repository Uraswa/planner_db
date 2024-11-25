CREATE OR REPLACE FUNCTION add_numbers(a int, b int)
RETURNS int AS $$
BEGIN
    RETURN a + b;
END;
$$ LANGUAGE plpgsql;

SELECT add_numbers(5, 10);