drop function if exists src_get_group_by_subject_id;
create function src_get_group_by_subject_id(sub_id integer)
returns integer
as
$$
    declare
        res integer;

begin
    SELECT gr.group_id FROM subject s
        JOIN user_group gr on s.group_id = gr.group_id
                    where s.subject_id = sub_id INTO res;
    return res;
end;
$$ LANGUAGE plpgsql;
SELECT src_get_group_by_subject_id(1)