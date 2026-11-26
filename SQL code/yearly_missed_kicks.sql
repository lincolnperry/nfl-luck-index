USE NFLLuck;
DROP TABLE IF EXISTS missed_kick_luck;

SELECT defteam AS team, COUNT(*) AS missed_field_goals, SUM(epa) * -1 AS kick_epa_gained, SUM(wpa) * -1 AS kick_wpa_gained
INTO missed_kick_luck
FROM pbp
WHERE field_goal_result = 'missed'
AND season >= 2022
GROUP BY defteam;

SELECT *
FROM missed_kick_luck;