create procedure router(path text, json jsonb)
as
$$
declare
    enpoint text;
begin
    enpoint = path;
end;
$$ language plpgsql;