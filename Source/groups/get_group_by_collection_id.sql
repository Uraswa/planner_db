drop function if exists src_get_group_by_collection_id;
create function src_get_group_by_collection_id(col_id integer)
returns integer
as
$$
    declare
        res integer;

begin
    SELECT gr.group_id FROM collection c
        JOIN subject s on (s.subject_id = c.subject_id)
        JOIN user_group gr on s.group_id = gr.group_id
                    where c.collection_id = col_id INTO res;
    return res;
end;
$$ LANGUAGE plpgsql;
SELECT src_get_group_by_collection_id(1)