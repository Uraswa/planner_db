drop function if exists api_get_subject;
create function api_get_subject(usr_id integer, usr_type user_type, json jsonb) returns text
as
$$
declare
    sb_id integer;
    grp_id integer;

begin

    sb_id := cast(jsonb_extract_path(json, 'subject_id') as integer);
    grp_id := src_get_group_by_subject_id(sb_id);

    RAISE NOTICE '%', grp_id;

    RETURN (SELECT json_build_object('entity', t) FROM
        (SELECT * FROM src_get_subjects(usr_id := usr_id, usr_type := usr_type, grp_id := grp_id, perpage := 9999999, page := 1) WHERE subject_id = sb_id) as t);

end;
$$ language plpgsql;
SELECT api_get_subject(19, 'default','{"subject_id":  3}')