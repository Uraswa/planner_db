drop function if exists src_get_group_by_solution_id;
create function src_get_group_by_solution_id(sol_id integer)
returns integer
as
$$
    declare
        res integer;

begin
    SELECT gr.group_id
        FROM solution sol
        JOIN task t on (t.task_id = sol.task_id)
        JOIN collection c on (c.collection_id = t.collection_id)
        JOIN subject s on (s.subject_id = c.subject_id)
        JOIN user_group gr on s.group_id = gr.group_id
                    where sol.solution_id = sol_id  INTO res;
    return res;
end;
$$ LANGUAGE plpgsql;
SELECT src_get_group_by_solution_id(1)