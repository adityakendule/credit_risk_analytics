# Credit Risk Analytics: MySQL + Power BI

Descriptive analysis of 28,638 loan records to identify which borrower and loan characteristics are associated with default, using MySQL for profiling and Power BI for an interactive dashboard.

<img width="1444" height="811" alt="Screenshot 2026-11-06 131311" src="https://github.com/user-attachments/assets/6c41ddee-e868-4cf3-a672-b8ccdb729d21" />



## Business Problem

Which borrower and loan factors (loan grade, affordability, income, credit history, loan purpose) are linked to higher observed default rates, and where is portfolio risk concentrated?

## Dataset

- **Source:** [Credit Risk Dataset (Kaggle)](https://www.kaggle.com/datasets/laotse/credit-risk-dataset)
- **Original size:** about 32.5K records
- **Used in analysis:** 28,638 records
- **Target:** `loan_status` (1 = defaulted, 0 = non-defaulted)

| Column | Description |
|---|---|
| `person_age` | Borrower age |
| `person_income` | Annual income |
| `person_home_ownership` | Rent / Own / Mortgage / Other |
| `person_emp_length` | Employment length (years) |
| `loan_intent` | Loan purpose |
| `loan_grade` | Loan grade (A to G) |
| `loan_amnt` | Loan amount |
| `loan_int_rate` | Interest rate |
| `loan_status` | Default indicator |
| `loan_percent_income` | Loan amount as a share of income |
| `cb_person_default_on_file` | Previous default flag (Y/N) |
| `cb_person_cred_hist_length` | Credit history length (years) |

## Tools

MySQL (profiling and analysis) | Power BI + DAX (dashboard)

## Methodology

1. **Data load:** imported into MySQL as `credit_risk_dataset`; added a technical `record_id` (the dataset has no customer ID).
2. **Profiling:** record counts, default distribution, missing and invalid value checks, category review.
3. **KPIs:** default rate, average loan amount, income, interest rate, total loan amount.
4. **Segmentation:** default rate by affordability band, loan grade, home ownership, credit history, previous default, and loan purpose + grade.
5. **Reconciliation:** SQL default rate checked against the Power BI DAX measure.
6. **Dashboard:** KPI cards, loan grade slicer, and six segment charts.

## Key Insights

| Finding | Result |
|---|---|
| Overall default rate | **21.66%** |
| Loan grade | Default rises sharply from grade D (59%) and reaches 98% in grade G, versus 10% in grade A |
| Affordability | Loan-to-income of 30% or more shows 62% to 75% default, versus 12% to 21% below 30% |
| Income | Default falls steadily as income rises: 54% under 25K, 9% above 100K |
| Credit history | Longer history does not reduce default here; 25+ years has the highest rate (27.18%) |
| Loan purpose | Loan amounts are spread fairly evenly across purposes; Education is the largest at $54M |

> Findings are observed associations, not causal effects.

## Data Quality

- About 3.9K rows with missing `loan_int_rate` or `person_emp_length` values were not loaded into MySQL, so the analysis uses the 28,638 complete records.
- A small number of implausible values (employment length of 123 years, age above 100) were identified and excluded.

## Limitations

- Descriptive analysis only: no machine learning model, regulatory credit score, or loss forecast.
- `defaulted_loan_amount_proxy` is the sum of loan amounts on defaulted records. It is **not** actual financial loss or unpaid principal.
- Excluding rows with missing values may introduce bias, so results reflect the complete-record subset only.
- Segment bands (affordability, credit history) are exploratory, not lending-policy thresholds.
- The dataset has no unique borrower ID, so each row is treated as a loan record.

## Repository Structure

```
credit-risk-analysis/
├── README.md
├── data/                      # raw CSV or Kaggle link
├── sql/
│   └── credit_risk_analysis.sql
├── powerbi/
│   └── credit_risk_dashboard.pbix
├── images/
    └── dashboard.png

```

## How to Run

1. Download the dataset from Kaggle and load it into MySQL as `credit_risk_dataset`.
2. Run `sql/credit_risk_analysis.sql` section by section.
3. Open `powerbi/credit_risk_dashboard.pbix` in Power BI Desktop and refresh the data source.
4. Compare the SQL default rate (Section 15) with the dashboard value (21.66%).

## Author

**Aditya Kendule**
MBA (Business Analytics), COEP Technological University, Pune
[LinkedIn](https://www.linkedin.com/in/aditya-kendule-a63059199/) | adityakendule2003@gmail.com
