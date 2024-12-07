create OR replace function trg_create_update_user_task_trigger_func() returns TRIGGER
as
$$
begin
    INSERT INTO history (task_id, date, user_id) VALUES (NEW.task_id, NOW(), NEW.user_id);
    return NEW;
end;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_create_update_user_task_trigger on user_task;
CREATE TRIGGER trg_create_update_user_task_trigger
BEFORE INSERT
ON user_task
FOR EACH ROW
EXECUTE FUNCTION trg_create_update_user_task_trigger_func();