USE NFLLuck;
DROP TABLE IF EXISTS int_drop_luck;


SELECT
    p.posteam AS team,
    COUNT(*) AS interception_worthy_throws,
    SUM(CASE WHEN p.interception = 0 THEN 1 ELSE 0 END) AS dropped_ints,
    SUM(CASE WHEN p.interception = 0 THEN 1 ELSE 0 END) * 1.0
    / COUNT(*) AS drop_rate,
    SUM(CASE WHEN p.interception = 0 THEN p.epa + 3.55 END) AS total_epa_gained,
    SUM(CASE WHEN p.interception = 0 THEN p.epa + 3.55 END) 
    / SUM(CASE WHEN p.interception = 0 THEN 1 ELSE 0 END) AS epa_saved_per_drop
INTO int_drop_luck
FROM pbp p
JOIN ftn_charting f
ON f.nflverse_game_id = p.game_id
AND f.nflverse_play_id = p.play_id
WHERE p.pass_attempt = 1
AND f.is_interception_worthy = 1
GROUP BY p.posteam;

SELECT team, drop_rate, epa_saved_per_drop
FROM int_drop_luck
ORDER BY drop_rate DESC;

SELECT *
FROM win_totals;