USE NFLLuck;
DROP TABLE IF EXISTS penalty_net;

WITH first_query AS (
SELECT penalty_team, SUM(epa) AS total_epa, SUM(wpa) AS total_wpa
FROM pbp
WHERE penalty_team = posteam
AND penalty_type IN ('Unsportsmanlike Conduct', 'Unnecessary Roughness', 'Taunting', 'Roughing the Passer', 'Roughing the Kicker', 'Offensive Pass Interference', 'Offensive Holding', 'Intentional Grounding', 'Illegal Contact', 'Disqualification', 'Defensive Pass Interference', 'Defensive Holding')
GROUP BY penalty_team
),
second_query AS (
SELECT penalty_team, SUM(epa) AS total_epa, SUM(wpa) AS total_wpa
FROM pbp
WHERE penalty_team = defteam
AND penalty_type IN ('Unsportsmanlike Conduct', 'Unnecessary Roughness', 'Taunting', 'Roughing the Passer', 'Roughing the Kicker', 'Offensive Pass Interference', 'Offensive Holding', 'Intentional Grounding', 'Illegal Contact', 'Disqualification', 'Defensive Pass Interference', 'Defensive Holding')
GROUP BY penalty_team
)
SELECT f.penalty_team AS team, 
f.total_epa - s.total_epa AS net_epa, 
f.total_wpa - s.total_wpa AS net_wpa
INTO penalty_net
FROM first_query f
JOIN second_query s ON f.penalty_team = s.penalty_team;

DROP TABLE IF EXISTS penalties_drawn;
DROP TABLE IF EXISTS penalty_luck;

WITH offense AS (
    -- on offense: the DEFENSE was flagged
    SELECT posteam AS team,
           COUNT(*) AS flags,
           SUM(epa) AS epa_gained,
           SUM(wpa) AS wpa_gained
    FROM pbp
    WHERE penalty_team = defteam
      AND penalty_type IN ('Unsportsmanlike Conduct', 'Unnecessary Roughness', 'Taunting',
                           'Roughing the Passer', 'Roughing the Kicker', 'Offensive Pass Interference',
                           'Offensive Holding', 'Intentional Grounding', 'Illegal Contact',
                           'Disqualification', 'Defensive Pass Interference', 'Defensive Holding')
    GROUP BY posteam
),
defense AS (
    -- on defense: the OFFENSE was flagged (sign flipped so positive = good for the defense)
    SELECT defteam AS team,
           COUNT(*) AS flags,
           SUM(epa) AS epa_gained,
           SUM(wpa) AS wpa_gained
    FROM pbp
    WHERE penalty_team = posteam
      AND penalty_type IN ('Unsportsmanlike Conduct', 'Unnecessary Roughness', 'Taunting',
                           'Roughing the Passer', 'Roughing the Kicker', 'Offensive Pass Interference',
                           'Offensive Holding', 'Intentional Grounding', 'Illegal Contact',
                           'Disqualification', 'Defensive Pass Interference', 'Defensive Holding')
    GROUP BY defteam
)
SELECT o.team,
       o.epa_gained - d.epa_gained       AS total_epa_gained,
       o.wpa_gained - d.wpa_gained       AS total_wpa_gained
INTO penalties_drawn
FROM offense o
JOIN defense d ON d.team = o.team;

USE NFLLuck;
DROP TABLE IF EXISTS penalty_luck;

SELECT d.team,
d.total_epa_gained + n.net_epa AS total_penalty_epa,
d.total_wpa_gained + n.net_wpa AS total_penalty_wpa
INTO penalty_luck
FROM penalties_drawn d
JOIN penalty_net n ON n.team = d.team;

SELECT * 
FROM penalty_luck;
