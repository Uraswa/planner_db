drop function if exists api_get_collections;
create function api_get_collections(usr_id integer, usr_type user_type, json jsonb) returns text
as
$$
declare
    perPage integer;
    page integer;
    sub_id integer;
begin

    perPage := CAST(jsonb_extract_path(json, 'perPage') as integer);
    page := CAST(jsonb_extract_path(json, 'page') as integer);
    sub_id := CAST(jsonb_extract_path(json, 'subject_id') as integer);

    RETURN (SELECT json_build_object(
            'entities', (
            SELECT json_agg(t)
            FROM src_get_collections(usr_id := usr_id, usr_type := usr_type, sb_id := sub_id, perpage := perPage, page := page) as t
            ),
            'count', (SELECT COUNT(*)
            FROM src_get_collections(usr_id := usr_id, usr_type := usr_type, sb_id := sub_id, perpage := 9999999, page := 1))
        ));
end;
$$ language plpgsql;
SELECT api_get_collections(19, 'default','{"page": 1, "perPage": 20, "subject_id": 3}')