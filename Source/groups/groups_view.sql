DROP VIEW IF EXISTS get_groups;
CREATE VIEW get_groups AS
SELECT ug.group_id,
       ug.name,
       ug.invite_link,
       ugm.username as creator_name,
       (SELECT count(*) from group_member gm0 WHERE gm0.group_id = ug.group_id) as members_count
FROM user_group ug
JOIN public.group_member gm on ug.group_id = gm.group_id and gm.is_creator = TRUE
JOIN users ugm on gm.user_id = ugm.user_id
WHERE ug.group_type = 'default';

SELECT * FROM get_groups;