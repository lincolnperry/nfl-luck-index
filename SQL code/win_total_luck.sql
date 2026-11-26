USE NFLLuck;
DROP TABLE IF EXISTS combined_schedule_luck;
DROP TABLE IF EXISTS home_table;
DROP TABLE IF EXISTS away_table;
DROP TABLE IF EXISTS fair_odds;
DROP TABLE IF EXISTS team_games;
DROP TABLE IF EXISTS sos_luck;
DROP TABLE IF EXISTS total_sos_luck_wins;

SELECT s.season, s.week, s.home_team AS home_team, s.away_team AS away_team, w.win_total AS away_win_totals, w.actual_wins, SUM(w.win_total - w.actual_wins) AS home_win_total_luck
FROM schedules s
JOIN win_totals w ON w.team = s.away_team
AND w.season = s.season
WHERE s.season = 2025
AND s.game_type = 'REG'
GROUP BY s.home_team, s.away_team, s.season, s.week, w.win_total, w.actual_wins
ORDER BY s.week;

SELECT s.home_team AS home_team, SUM(w.win_total - w.actual_wins) AS home_win_total_luck
INTO home_table
FROM schedules s
JOIN win_totals w ON w.team = s.away_team
AND w.season = s.season
WHERE s.game_type = 'REG'
GROUP BY s.home_team;

SELECT s.away_team AS away_team, SUM(w.win_total - w.actual_wins) AS away_win_total_luck
INTO away_table
FROM schedules s
JOIN win_totals w ON w.team = s.home_team
AND w.season = s.season
WHERE s.game_type = 'REG'
GROUP BY s.away_team;

SELECT h.home_team AS team, h.home_win_total_luck + a.away_win_total_luck AS total_schedule_luck
INTO combined_schedule_luck
FROM home_table h
JOIN away_table a ON a.away_team = h.home_team;


SELECT *
FROM combined_schedule_luck;

SELECT season, week, home_team, away_team,
       home_moneyline, away_moneyline,
       CASE WHEN home_moneyline < 0 THEN -home_moneyline / (-home_moneyline + 100.0)
            ELSE 100.0 / (home_moneyline + 100) END AS home_raw,
       CASE WHEN away_moneyline < 0 THEN -away_moneyline / (-away_moneyline + 100.0)
            ELSE 100.0 / (away_moneyline + 100) END AS away_raw
FROM schedules
WHERE game_type = 'REG';

SELECT *, home_raw / (home_raw + away_raw) AS home_fair,
          away_raw / (home_raw + away_raw) AS away_fair
INTO fair_odds
FROM (
    SELECT season, week, home_team, away_team,
       home_moneyline, away_moneyline,
       CASE WHEN home_moneyline < 0 THEN -home_moneyline / (-home_moneyline + 100.0)
            ELSE 100.0 / (home_moneyline + 100) END AS home_raw,
       CASE WHEN away_moneyline < 0 THEN -away_moneyline / (-away_moneyline + 100.0)
            ELSE 100.0 / (away_moneyline + 100) END AS away_raw
FROM schedules
WHERE game_type = 'REG' AND result IS NOT NULL
) t;

SELECT season, home_team AS team, away_team AS opp, home_fair AS implied_p
INTO team_games
FROM fair_odds
UNION ALL 
SELECT season, away_team AS team, home_team AS opp, away_fair AS implied_p
FROM fair_odds;

SELECT s.season, s.team, COUNT(*) AS games, AVG(w.win_total / 17) AS opp_preseason_wpct, AVG(o.implied_p) AS opp_market_wpct
INTO sos_luck
FROM team_games s
JOIN team_games o ON o.team = s.opp AND o.season = s.season AND o.opp <> s.team
JOIN win_totals w ON w.team = s.opp AND w.season = o.season
GROUP BY s.season, s.team;

SELECT l.team, SUM((opp_preseason_wpct - opp_market_wpct) * g.games_played) AS total_sos_luck_wins
FROM sos_luck l
JOIN (
     SELECT season, team, COUNT(*) AS games_played
     FROM team_games
     GROUP BY team, season
) g ON g.team = l.team AND g.season = l.season
GROUP BY l.team;

USE NFLLuck;
DROP TABLE IF EXISTS total_sos_luck_wins;

SELECT l.team,
       SUM((l.opp_preseason_wpct - l.opp_market_wpct) * g.games_played) AS total_sos_luck_wins
INTO total_sos_luck_wins
FROM sos_luck l
JOIN (
    SELECT season, team, COUNT(*) AS games_played
    FROM team_games
    GROUP BY season, team
) g ON g.season = l.season AND g.team = l.team
GROUP BY l.team;                 -- team only, so the seasons get added together

SELECT * FROM total_sos_luck_wins;   -- should be 32