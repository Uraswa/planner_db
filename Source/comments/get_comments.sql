drop function if exists src_get_comments;
create function src_get_comments(usr_id integer, solut_id integer, perPage integer, page integer)
returns TABLE (comment_id integer, text text, can_modify boolean)
as
$$
    declare
        offst integer;

begin
    offst := (page - 1) * perPage;
    RETURN QUERY
    SELECT
    com.comment_id as comment_id,
    com.text as text,
    (com.creator_id = usr_id) as can_modify
    FROM comment com
    JOIN solution s ON (s.solution_id = com.comment_id)
    JOIN task ts ON (ts.task_id = s.task_id)
    JOIN collection col ON (col.collection_id = ts.collection_id)
    JOIN subject sb ON col.subject_id = sb.subject_id
    JOIN user_group gr on (gr.group_id = sb.group_id)
    JOIN group_member gm on (gr.group_id = gm.group_id and gm.user_id = usr_id)
    WHERE com.solution_id = solut_id
    OFFSET offst
    LIMIT perPage;
end;
$$ LANGUAGE plpgsql;