# Healthcare-cost-quality-intelligence-pipeline
End-to-end healthcare analytics pipeline using T-SQL (SSMS) and Power BI across 101,766 hospital encounters to analyze &lt;30-day readmission risk, medication/stay dynamics, and care intensity.


## Dashboard Preview

![Healthcare Cost & Quality Dashboard](assets/dashboard_preview.png)

---

## Business Problem & Objectives
Unplanned `<30`-day hospital readmissions drive avoidable clinical complications and significant financial penalties. This project transforms raw inpatient encounter records into an executive decision-support dashboard designed to answer:
1. **Risk Stratification:** Which patient cohorts experience the highest `<30`-day readmission rates?
2. **Treatment & Stay Dynamics:** How do length of stay and inpatient medication adjustments (`change`, `insulin`) influence readmission risk?
3. **Care Resource Intensity:** How do laboratory procedures (`num_lab_procedures`), medication counts (`num_medications`), and hospital stay duration (`time_in_hospital`) scale across high-risk clinical groups?

---

## Key Analytical Findings
* **Overall Cohort Baseline:** Across **101,766** total encounters (**102K**), `<30`-day readmissions account for **11.16%** (**~11K** encounters), with an average stay of **4.40 days**, **43.10 lab procedures**, and **16.02 medications**.
* **Stay Duration & Medication Change Gap:** Extended inpatient stays combined with medication adjustments (`Ch`) exhibit higher `<30`-day readmission rates (**13.43%**) compared to shorter stays without medication changes (`No`, **8.80%**).
* **Insulin Adjustment Breakdown:** Active insulin adjustments show higher `<30`-day readmission rates—**13.90%** (`Down`) and **12.99%** (`Up`)—compared to `Steady` (**11.13%**) and `No` (**10.04%**), while `Up` shows the highest average stay (**5.24 days**) and medication count (**19.63**).
* **High-Risk Resource Intensity:** Higher-acuity/high-risk segments reach up to a **15.49%** `<30`-day readmission rate alongside elevated care intensity (**9.3 avg stay days**, **51.4 avg labs**, and **25.4 avg medications**).
* **Age & Readmission Distribution:** Encounter volume peaks in the **`[70-80)`** and **`[60-70)`** age brackets, with overall readmission outcomes split across `NO` (**53.91%**), `>30` (**34.93%**), and `<30` (**11.16%**).

---

## Technical Architecture

### 1. Data Engineering & Hygiene (`T-SQL` / `HealthcareMIS`)
* Built a semantic view (`dbo.vw_hospital_admissions_clean`) over raw encounter records in SQL Server (`SSMS 21`).
* Standardized missing clinical indicators and handled stacked lookup metadata in `IDS_mapping` safely using `TRY_CAST` and `LTRIM/RTRIM`.

### 2. Semantic Modeling & DAX (`Power BI`)
Connected Power BI Desktop to `HealthcareMIS` via **Import mode** and authored modular DAX measures:
* `Total Encounters = COUNTROWS(vw_hospital_admissions_clean)`
* `<30-Day Readmissions = CALCULATE(COUNTROWS(vw_hospital_admissions_clean), vw_hospital_admissions_clean[readmitted] = "<30")`
* `<30-Day Readmission Rate % = DIVIDE([<30-Day Readmissions], [Total Encounters], 0)`
* `Avg Stay Days = AVERAGE(vw_hospital_admissions_clean[time_in_hospital])`
* `Avg Labs = AVERAGE(vw_hospital_admissions_clean[num_lab_procedures])`
* `Avg Meds = AVERAGE(vw_hospital_admissions_clean[num_medications])`

---

## How to Reproduce
1. **Database Setup:** Execute your SQL script in SQL Server Management Studio (`HealthcareMIS` database) to create `dbo.vw_hospital_admissions_clean` and run the analytical queries.
2. **Interactive Dashboard:** Open the `.pbix` file in Power BI Desktop and use the `change` and `gender` slicers to explore subgroup performance.

---

## Tech Stack
* **Database & ETL:** T-SQL, Microsoft SQL Server, SQL Server Management Studio (SSMS 21)
* **BI & Visualization:** Power BI Desktop, DAX
