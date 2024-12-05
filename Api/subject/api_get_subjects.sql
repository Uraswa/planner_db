drop function if exists api_get_subjects;
create function api_get_subjects(usr_id integer, usr_type user_type, json jsonb) returns text
as
$$
declare
    perPage integer;
    page integer;
    grp_id integer;
begin

    perPage := CAST(jsonb_extract_path(json, 'perPage') as integer);
    page := CAST(jsonb_extract_path(json, 'page') as integer);
    grp_id := CAST(jsonb_extract_path(json, 'group_id') as integer);

    RETURN (SELECT json_build_object(
            'entities', (
            SELECT json_agg(t)
            FROM src_get_subjects(usr_id := usr_id, usr_type := usr_type, grp_id := grp_id, perpage := perPage, page := page) as t
            ),
            'count', (SELECT COUNT(*)
            FROM src_get_subjects(usr_id := usr_id, usr_type := usr_type, grp_id := grp_id, perpage := 9999999, page := 1))
        ));
end;
$$ language plpgsql;
SELECT api_get_subjects(19, 'default','{"page": 1, "perPage": 20, "group_id": 13}')