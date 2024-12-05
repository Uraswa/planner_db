drop function if exists src_get_group_by_group_id;
create function src_get_group_by_group_id(grp_id integer)
returns user_group
as
$$
    declare
        res user_group;

begin
    SELECT FROM user_group WHERE group_id = grp_id INTO res;
    return res;
end;
$$ LANGUAGE plpgsql;