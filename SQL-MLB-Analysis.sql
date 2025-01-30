
-- A) In Each Decade, How Many Schools Were There That Produced MLB Players?
SELECT  FLOOR(yearID / 10) * 10 AS decade, COUNT(DISTINCT schoolID) AS num_schools
FROM    schools
GROUP BY decade
ORDER BY decade;

-- B) What Are The Names Of The Top 5 Schools That Produced The Most Players?
SELECT  scd.name_full, COUNT(DISTINCT s.playerID) AS num_of_players
FROM    schools s 
LEFT JOIN school_details scd ON scd.schoolID = s.schoolID
GROUP BY scd.name_full
ORDER BY num_of_players DESC
LIMIT 5; 

-- C) For Each Decade, What Were The Names Of The Top 3 Schools That Produced The Most Players?
WITH scd_cte AS (
    SELECT  FLOOR(yearID / 10) * 10 AS decade, scd.name_full, 
            COUNT(DISTINCT s.playerID) AS num_of_players
    FROM    schools s 
    LEFT JOIN school_details scd ON scd.schoolID = s.schoolID
    GROUP BY scd.name_full, decade
),
rank_players AS (
    SELECT  decade, name_full, num_of_players,
            ROW_NUMBER() OVER (PARTITION BY decade ORDER BY num_of_players DESC) AS players_per_decade
    FROM    scd_cte
)
SELECT  decade, name_full, num_of_players
FROM    rank_players
WHERE   players_per_decade <= 3
ORDER BY decade DESC;

-- D) Return The Top 20% Of Teams In Terms Of Average Annual Spending
WITH salary_cte AS (
    SELECT  teamID, yearID, SUM(salary) AS sum_salary 
    FROM    salaries
    GROUP BY teamID, yearID
),
avg_cte AS (
    SELECT  teamID, AVG(sum_salary) AS avg_spent,
            NTILE(5) OVER (ORDER BY AVG(sum_salary) DESC) AS spent_tiles 
    FROM    salary_cte
    GROUP BY teamID
)
SELECT  teamID, ROUND(avg_spent / 1000000, 1) AS avg_spend_millions
FROM    avg_cte
WHERE   spent_tiles = 1;

-- E) For Each Team, Show The Cumulative Sum Of Spending Over The Years
WITH salary_cte AS (
    SELECT  teamID, yearID, SUM(salary) AS sum_salary 
    FROM    salaries
    GROUP BY teamID, yearID
)
SELECT  teamID, yearID,
        SUM(sum_salary) OVER (PARTITION BY teamID ORDER BY yearID) AS cumulative_sum
FROM    salary_cte;

-- F) For Each Player, Calculate Their Age At Their First (Debut) Game, Their Last Game, 
--    And Their Career Length (All In Years). Sort From Longest Career To Shortest Career.
SELECT  nameGiven,
        TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE), debut) AS start_age,
        TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE), finalGame) AS end_age,
        TIMESTAMPDIFF(YEAR, debut, finalGame) AS career_length
FROM    players
ORDER BY career_length DESC;

-- G) How Many Players Started And Ended On The Same Team And Also Played For Over A Decade?
SELECT  p.nameGiven, s.yearID AS starting_year, s.teamID AS starting_team,
        e.yearID AS ending_year, e.teamID AS ending_team
FROM    players p 
INNER JOIN salaries s ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID
INNER JOIN salaries e ON p.playerID = e.playerID AND YEAR(p.finalGame) = e.yearID
WHERE   s.teamID = e.teamID 
AND     e.yearID - s.yearID > 10;


-- h) Which players have the same birthday?
WITH B_day AS (SELECT nameGiven,CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birthdate 
    FROM players
)
SELECT birthdate, GROUP_CONCAT(nameGiven SEPARATOR ', ') AS players_with_same_birthday
FROM B_day
GROUP BY birthdate
HAVING COUNT(*) > 1
ORDER BY birthdate;

