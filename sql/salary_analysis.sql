use salary_analysis;

-- table name => respondents & respondent_language

SELECT 
    *
FROM
    respondents;

SELECT 
    CASE
        WHEN work_exp >= 0 AND work_exp <= 2 THEN '0-2'
        WHEN work_exp > 2 AND work_exp <= 5 THEN '2-5'
        WHEN work_exp > 5 AND work_exp <= 10 THEN '5-10'
        WHEN work_exp > 10 AND work_exp <= 15 THEN '10-20'
        WHEN work_exp > 15 AND work_exp <= 20 THEN '15-20'
        ELSE '20+'
    END AS work_exp_group,
    COUNT(respondent_id) AS total_respondent,
    ROUND(AVG(salary_usd), 2) AS avg_salary,
    ROUND(STD(salary_usd), 2) AS std_salary
FROM
    respondents
GROUP BY work_exp_group
ORDER BY MIN(work_exp);

-- -----------------------------------------

SELECT 
    lang.language AS respondent_language,
    ROUND(AVG(res.salary_usd), 2) AS avg_salary,
    COUNT(res.respondent_id) AS total_respondent
FROM
    respondents res,
    respondent_language lang
WHERE
    res.respondent_id = lang.respondent_id
GROUP BY lang.language
HAVING total_respondent > 5
ORDER BY avg_salary DESC
LIMIT 10;


-- -----------------------------------------

SELECT 
    dev_type AS Role,
    ROUND(AVG(res.salary_usd), 2) AS avg_salary,
    COUNT(res.respondent_id) AS total_respondent
FROM
    respondents res,
    respondent_language lang
WHERE
    res.respondent_id = lang.respondent_id
GROUP BY res.dev_type
HAVING total_respondent > 5
ORDER BY avg_salary DESC
LIMIT 10;

-- -----------------------------------------

-- Top 3 languagaes across different roles

with ranked_table as (
SELECT 
    dev_type as Role,
    lang.language as language,
	ROUND(AVG(res.salary_usd), 2) AS avg_salary,
    COUNT(*) AS n,
    rank() over(partition by res.dev_type order by  ROUND(AVG(res.salary_usd), 2) desc ) as ranking
FROM
    respondents res,
    respondent_language lang
WHERE
    res.respondent_id = lang.respondent_id
GROUP BY res.dev_type, lang.language
HAVING COUNT(*) >= 20
)

select * from ranked_table
where ranking <=3
order by role, ranking;

-- -----------------------------------------

SELECT 
    ed_level AS education,
    ROUND(AVG(res.salary_usd), 2) AS avg_salary,
    COUNT(res.respondent_id) AS total_respondent
FROM
    respondents res,
    respondent_language lang
WHERE
    res.respondent_id = lang.respondent_id
GROUP BY res.ed_level
HAVING total_respondent > 5
ORDER BY avg_salary DESC
LIMIT 10;

-- Salary distribution across org_size
SELECT 
    org_size AS org_size,
    ROUND(AVG(res.salary_usd), 2) AS avg_salary,
    COUNT(res.respondent_id) AS total_respondent
FROM
    respondents res,
    respondent_language lang
WHERE
    res.respondent_id = lang.respondent_id
GROUP BY res.org_size
HAVING total_respondent > 5
ORDER BY avg_salary DESC
LIMIT 10;

-- Salary distribution across remote_work
SELECT 
    remote_work AS remote_work,
    ROUND(AVG(res.salary_usd), 2) AS avg_salary,
    COUNT(res.respondent_id) AS total_respondent
FROM
    respondents res,
    respondent_language lang
WHERE
    res.respondent_id = lang.respondent_id
GROUP BY res.remote_work
HAVING total_respondent > 5
ORDER BY avg_salary DESC
LIMIT 10;