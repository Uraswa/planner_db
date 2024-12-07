drop function if exists src_calculate_next_repeat_data;
create function src_calculate_next_repeat_data(repeat_index int, rule0 varchar) returns timestamp
as
$$
declare
    total_count integer;
    add_interval varchar;
begin
    total_count := array_length(string_to_array(rule0, ';'), 1);
    add_interval := '';

    IF repeat_index >= total_count THEN
        add_interval := split_part(rule0, ';', repeat_index + 1) || ' days';
        RAISE NOTICE '%', add_interval;
        return now() + interval add_interval;
    ELSE
        add_interval := split_part(split_part(rule0, ';', total_count), '...', 1) || ' days';
        RAISE NOTICE '%', add_interval;
        return now() + interval add_interval;
    end if;
end;
$$ language plpgsql;

SELECT * FROM src_calculate_next_repeat_data(1, '1;2;3;7;14...14')