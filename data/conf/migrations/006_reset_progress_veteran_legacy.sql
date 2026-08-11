INSERT INTO quest (char_id, quest_id, state)
SELECT char_id, 2409290506, 0
FROM quest
WHERE quest_id = 0 AND state = 255;

DELETE FROM quest WHERE quest_id != 2409290506;

UPDATE stat SET level = 1, experience = 0;
