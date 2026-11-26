USE NFLLuck;
DROP TABLE IF EXISTS ints_saved;
DROP TABLE IF EXISTS int_luck_wins;
DROP TABLE IF EXISTS total_luck;

SELECT team, SUM(actual_wins) / (CASE WHEN team = 'BUF' OR team = 'CIN' THEN 67 ELSE 68 END) AS win_pct
FROM win_totals
WHERE season < 2026
GROUP BY team;

SELECT team, SUM((drop_rate - 0.502844500631) * interception_worthy_throws) AS ints_saved
INTO ints_saved
FROM int_drop_luck
GROUP BY team;

SELECT team, ints_saved * 0.08254601793028835 AS int_luck_wins
INTO int_luck_wins
FROM ints_saved;

SELECT i.team, SUM(i.int_luck_wins + t.total_sos_luck_wins + p.total_penalty_wpa + (m.kick_wpa_gained - 1.7692394869895838)) AS total_luck_wins
INTO total_luck
FROM int_luck_wins i
JOIN total_sos_luck_wins t ON t.team = i.team 
JOIN penalty_luck p ON p.team = i.team
JOIN missed_kick_luck m ON m.team = i.team
GROUP BY i.team;

SELECT *
FROM total_luck;

USE NFLLuck;
SELECT 'int_luck_wins' AS table_name, COUNT(*) AS rows FROM int_luck_wins
UNION ALL SELECT 'total_sos_luck_wins', COUNT(*) FROM total_sos_luck_wins
UNION ALL SELECT 'penalty_luck',        COUNT(*) FROM penalty_luck
UNION ALL SELECT 'missed_kick_luck',    COUNT(*) FROM missed_kick_luck;