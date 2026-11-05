/*
============================================================
CREDIT RISK ANALYTICS PROJECT
SQL ANALYSIS - MYSQL
============================================================

Purpose:
Analyze borrower and loan-level data to understand observed
default patterns, affordability, credit history, loan grades,
loan purposes, and portfolio-level risk indicators.

Dataset table:
    credit_risk_dataset

Important interpretation:
    loan_status = 1  -> Defaulted
    loan_status = 0  -> Non-defaulted

This analysis is descriptive. It does NOT create a machine
learning model, a regulatory credit score, or an actual loss
forecast.

============================================================
SECTION 1 - INITIAL DATA CHECK
============================================================
*/

-- View the complete source table before beginning analysis.
SELECT * FROM credit_risk_dataset;


/*
============================================================
SECTION 2 - ADD UNIQUE RECORD ID
============================================================

Purpose:
Create a technical identifier for each record so individual
rows can be referenced consistently in the project.

Note:
This is a record identifier, not a customer ID. The dataset
does not provide a unique borrower/customer identifier.
*/

ALTER TABLE credit_risk_dataset
ADD COLUMN record_id INT AUTO_INCREMENT PRIMARY KEY;


/*
============================================================
SECTION 3 - BASIC DATA PROFILING
============================================================

Purpose:
Check the total number of records and the number of distinct
loan-status values in the dataset.
*/

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT loan_status) AS distinct_status_values
FROM credit_risk_dataset;


/*
============================================================
SECTION 4 - DEFAULT STATUS DISTRIBUTION
============================================================

Purpose:
Understand how many records are defaulted versus
non-defaulted and calculate their percentage of the
overall dataset.
*/

SELECT
    loan_status,
    COUNT(*) AS record_count,
    ROUND(100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM credit_risk_dataset), 2) AS record_pct
FROM credit_risk_dataset
GROUP BY loan_status
ORDER BY loan_status;


/*
============================================================
SECTION 5 - MISSING VALUE ANALYSIS
============================================================

Purpose:
Identify missing values across all important borrower,
loan, and credit-history fields.

This step helps determine whether data-quality issues could
affect subsequent analysis.
*/

SELECT
    COUNT(*) AS total_records,
    SUM(person_age IS NULL) AS missing_age,
    SUM(person_income IS NULL) AS missing_income,
    SUM(person_home_ownership IS NULL) AS missing_home_ownership,
    SUM(person_emp_length IS NULL) AS missing_emp_length,
    SUM(loan_intent IS NULL) AS missing_loan_intent,
    SUM(loan_grade IS NULL) AS missing_loan_grade,
    SUM(loan_amnt IS NULL) AS missing_loan_amount,
    SUM(loan_int_rate IS NULL) AS missing_interest_rate,
    SUM(loan_status IS NULL) AS missing_loan_status,
    SUM(loan_percent_income IS NULL) AS missing_income_ratio,
    SUM(cb_person_default_on_file IS NULL) AS missing_previous_default,
    SUM(cb_person_cred_hist_length IS NULL) AS missing_credit_history
FROM credit_risk_dataset;


/*
============================================================
SECTION 6 - INVALID VALUE CHECKS AND REMOVING THEM
============================================================

Purpose:
Identify records containing potentially invalid numeric
values or unexpected loan-status values. 

These checks flag records for investigation; they do not
automatically delete or modify them.
*/

SELECT
    SUM(person_age <= 0) AS invalid_age,
    SUM(person_income <= 0) AS invalid_income,
    SUM(loan_amnt <= 0) AS invalid_loan_amount,
    SUM(person_emp_length < 0) AS invalid_employment_length,
    SUM(loan_int_rate <= 0) AS invalid_interest_rate,
    SUM(loan_percent_income < 0) AS invalid_income_ratio,
    SUM(
        loan_status IS NULL
        OR loan_status NOT IN (0, 1)
    ) AS invalid_loan_status
FROM credit_risk_dataset;

SELECT COUNT(*) FROM credit_risk_dataset
WHERE person_emp_length > 60 OR person_age > 100;

DELETE FROM credit_risk_dataset
WHERE person_emp_length > 60
   OR person_age > 100;

/*
============================================================
SECTION 7 - DISTINCT CATEGORY VALUES
============================================================

Purpose:
Review the categorical values available in the dataset
before using them for segmentation and dashboard filters.
*/

-- Review home-ownership categories.
SELECT DISTINCT person_home_ownership
FROM credit_risk_dataset;

-- Review loan-purpose categories.
SELECT DISTINCT loan_intent
FROM credit_risk_dataset;

-- Review loan-grade categories.
SELECT DISTINCT loan_grade
FROM credit_risk_dataset;

-- Review previous-default indicator values.
SELECT DISTINCT cb_person_default_on_file
FROM credit_risk_dataset;


/*
============================================================
SECTION 8 - PORTFOLIO-LEVEL CREDIT RISK KPIs
============================================================

Purpose:
Calculate the main portfolio metrics that will support
the Power BI executive dashboard.

Key metrics:
    - Total loan records
    - Defaulted records
    - Non-defaulted records
    - Default rate
    - Average loan amount
    - Average annual income
    - Average interest rate
    - Total recorded loan amount
    - Loan amount associated with defaulted records

Important:
defaulted_loan_amount_proxy represents the sum of loan
amounts attached to defaulted records. It should NOT be
interpreted as actual financial loss or outstanding
unpaid principal.
*/

SELECT
    COUNT(*) AS total_loan_records,

    SUM(CASE
        WHEN loan_status = 1 THEN 1 ELSE 0
    END) AS defaulted_records,

    SUM(CASE
        WHEN loan_status = 0 THEN 1 ELSE 0
    END) AS non_defaulted_records,

    ROUND(
        100.0 * SUM(CASE
            WHEN loan_status = 1 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,

    ROUND(AVG(person_income), 2) AS avg_annual_income,

    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate,

    SUM(loan_amnt) AS total_recorded_loan_amount,

    SUM(CASE
        WHEN loan_status = 1 THEN loan_amnt
        ELSE 0
    END) AS defaulted_loan_amount_proxy

FROM credit_risk_dataset
WHERE loan_status IN (0, 1);


/*
============================================================
SECTION 9 - DEFAULT RATE BY AFFORDABILITY BAND
============================================================

Purpose:
Examine whether observed default rates differ according to
loan amount relative to borrower income.

The thresholds below are exploratory analytical bands.
They are not regulatory or lending-policy thresholds.

Before using these bands, confirm that loan_percent_income
is stored as a decimal ratio (for example, 0.20 = 20%).
*/

SELECT
    CASE
        WHEN loan_percent_income < 0.10
            THEN '1. Below 10%'
        WHEN loan_percent_income < 0.20
            THEN '2. 10%-20%'
        WHEN loan_percent_income < 0.30
            THEN '3. 20%-30%'
        WHEN loan_percent_income >= 0.30
            THEN '4. 30%+'
        ELSE '5. Unknown'
    END AS affordability_band,

    COUNT(*) AS total_records,

    SUM(CASE
        WHEN loan_status = 1 THEN 1 ELSE 0
    END) AS defaulted_records,

    ROUND(
        100.0 * SUM(CASE
            WHEN loan_status = 1 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct

FROM credit_risk_dataset
WHERE loan_status IN (0, 1)
GROUP BY affordability_band
ORDER BY affordability_band;


/*
============================================================
SECTION 10 - DEFAULT RATE BY PREVIOUS DEFAULT HISTORY
============================================================

Purpose:
Compare observed default rates between borrowers/records
with different previous-default indicators.

This identifies an association in the dataset; it does not
establish causation.
*/

SELECT
    cb_person_default_on_file AS previous_default_flag,
    COUNT(*) AS total_records,

    SUM(CASE
        WHEN loan_status = 1 THEN 1 ELSE 0
    END) AS defaulted_records,

    ROUND(
        100.0 * SUM(CASE
            WHEN loan_status = 1 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM credit_risk_dataset
WHERE loan_status IN (0, 1)
GROUP BY cb_person_default_on_file
ORDER BY default_rate_pct DESC;


/*
============================================================
SECTION 11 - LOAN GRADE + AFFORDABILITY ANALYSIS
============================================================

Purpose:
Combine loan grade and affordability into a two-dimensional
risk segmentation.

This analysis can later be represented as a Power BI matrix
or heatmap.
*/

SELECT
    loan_grade,

    CASE
        WHEN loan_percent_income < 0.10
            THEN 'Below 10%'
        WHEN loan_percent_income < 0.20
            THEN '10%-20%'
        WHEN loan_percent_income < 0.30
            THEN '20%-30%'
        WHEN loan_percent_income >= 0.30
            THEN '30%+'
        ELSE 'Unknown'
    END AS affordability_band,

    COUNT(*) AS total_records,

    SUM(CASE
        WHEN loan_status = 1 THEN 1 ELSE 0
    END) AS defaulted_records,

    ROUND(
        100.0 * SUM(CASE
            WHEN loan_status = 1 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    SUM(loan_amnt) AS total_recorded_loan_amount,

    SUM(CASE
        WHEN loan_status = 1 THEN loan_amnt
        ELSE 0
    END) AS defaulted_loan_amount_proxy

FROM credit_risk_dataset
WHERE loan_status IN (0, 1)
GROUP BY
    loan_grade,
    CASE
        WHEN loan_percent_income < 0.10 THEN 'Below 10%'
        WHEN loan_percent_income < 0.20 THEN '10%-20%'
        WHEN loan_percent_income < 0.30 THEN '20%-30%'
        WHEN loan_percent_income >= 0.30 THEN '30%+'
        ELSE 'Unknown'
    END
ORDER BY default_rate_pct DESC;


/*
============================================================
SECTION 12 - DEFAULT RATE BY HOME OWNERSHIP
============================================================

Purpose:
Compare borrower income, average loan amount, and observed
default rate across home-ownership categories.
*/

SELECT
    person_home_ownership,
    COUNT(*) AS total_records,

    ROUND(AVG(person_income), 2) AS avg_annual_income,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,

    ROUND(
        100.0 * SUM(CASE
            WHEN loan_status = 1 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct

FROM credit_risk_dataset
WHERE loan_status IN (0, 1)
GROUP BY person_home_ownership
ORDER BY default_rate_pct DESC;


/*
============================================================
SECTION 13 - DEFAULT RATE BY CREDIT HISTORY LENGTH
============================================================

Purpose:
Group borrowers/records according to credit-history length
and compare their observed default rates.

The bands are exploratory and intended for portfolio analysis.
*/

SELECT
    CASE
        WHEN cb_person_cred_hist_length BETWEEN 2 AND 4  THEN '2-4 yrs'
        WHEN cb_person_cred_hist_length BETWEEN 5 AND 9  THEN '5-9 yrs'
        WHEN cb_person_cred_hist_length BETWEEN 10 AND 14 THEN '10-14 yrs'
        WHEN cb_person_cred_hist_length BETWEEN 15 AND 19 THEN '15-19 yrs'
        WHEN cb_person_cred_hist_length BETWEEN 20 AND 24 THEN '20-24 yrs'
        WHEN cb_person_cred_hist_length >= 25 THEN '25+ yrs'
        ELSE 'Unknown'
    END AS credit_history_band,

    COUNT(*) AS total_records,

    SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END) AS defaulted_records,

    ROUND(
        100.0 * SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS default_rate_pct

FROM credit_risk_dataset
WHERE loan_status IN (0, 1)
GROUP BY credit_history_band
ORDER BY MIN(cb_person_cred_hist_length);


/*
============================================================
SECTION 14 - TOP HIGHER-RISK LOAN SEGMENTS
============================================================

Purpose:
Identify loan-purpose + loan-grade combinations with higher
observed default rates while requiring at least 100 records.

The 100-record threshold is an exploratory reporting rule,
not a statistical guarantee of reliability.
*/

SELECT
    loan_intent,
    loan_grade,
    COUNT(*) AS total_records,

    SUM(CASE
        WHEN loan_status = 1 THEN 1 ELSE 0
    END) AS defaulted_records,

    ROUND(
        100.0 * SUM(CASE
            WHEN loan_status = 1 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct

FROM credit_risk_dataset
WHERE loan_status IN (0, 1)
GROUP BY loan_intent, loan_grade
HAVING COUNT(*) >= 100
ORDER BY default_rate_pct DESC
LIMIT 10;


/*
============================================================
SECTION 15 - FINAL VALIDATION / POWER BI RECONCILIATION
============================================================

Purpose:
Produce the core default-rate figures that should be
reconciled against the equivalent Power BI DAX measures.

The SQL result and Power BI result should match when they
use the same dataset and filter context.
*/

SELECT
    COUNT(*) AS valid_records,

    SUM(CASE
        WHEN loan_status = 1 THEN 1 ELSE 0
    END) AS defaulted_records,

    ROUND(
        100.0 * SUM(CASE
            WHEN loan_status = 1 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct

FROM credit_risk_dataset
WHERE loan_status IN (0, 1);


/*
============================================================
END OF CREDIT RISK SQL ANALYSIS
============================================================

Next step:
Connect credit_risk_dataset to Power BI and build the
interactive Credit Risk Portfolio Analytics dashboard.

Recommended Power BI sections:
    1. Portfolio Overview
    2. Risk Segmentation
    3. Affordability & Credit History
    4. Data Quality / Methodology

Remember:
SQL is used for data profiling and analytical preparation.
Power BI should use the detailed dataset plus DAX measures
for interactive filtering and visualization.
============================================================
*/

