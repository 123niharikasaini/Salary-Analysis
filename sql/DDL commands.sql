create database salary_analysis;
use salary_analysis;

CREATE TABLE IF NOT EXISTS respondents (
    respondent_id INT PRIMARY KEY ,
    salary_usd DECIMAL(10 , 2 ) NOT NULL,
    ed_level VARCHAR(150),
    work_exp INT NOT NULL,
    deorg_sizev_type VARCHAR(100),
    org_size VARCHAR(100),
    remote_work VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS respondent_language (
    lang_id INT PRIMARY KEY AUTO_INCREMENT,
    respondent_id INT,
    language VARCHAR(50),
    FOREIGN KEY (respondent_id)
        REFERENCES respondents (respondent_id)
);

-- =================================================================
SELECT 
    COUNT(*)
FROM
    respondents;

SELECT 
    COUNT(*)
FROM
    respondent_language;
SELECT 
    COUNT(DISTINCT respondent_id)
FROM
    respondent_language;