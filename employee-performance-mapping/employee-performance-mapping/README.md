# Employee Performance Mapping (SQL)

A MySQL project for **ScienceQtech**, a data science startup preparing for its annual appraisal cycle. As the Junior DBA, the goal is to analyse employee data (performance, projects, departments, experience, salary) and turn it into insights for fair appraisals, training needs and bonus payouts.

## Objectives
- Validate employee roles against experience-based standards
- Rank employees by experience
- Identify high and low performers
- Calculate salary bonuses
- Improve query performance with views and indexes

## Tech Stack
- MySQL 8.0+ (window functions and CTEs are used)
- MySQL Workbench (data import wizard, ER diagram)

## Dataset
Three CSV files loaded into a database named `employee`:

| File | Table | Description |
|------|-------|-------------|
| `emp_record_table.csv` | `emp_record_table` | Employee demographics, role, department, rating, experience, salary, country, continent |
| `proj_table.csv` | `proj_table` | Company projects: domain, duration, status |
| `data_science_team.csv` | `data_science_team` | Employees in the Data Science team |

> Place the CSVs in the `data/` folder. If the data is confidential, add them to `.gitignore` instead of committing them.

## Repository Structure
```
employee-performance-mapping/
├── README.md
├── .gitignore
├── sql/
│   └── employee_performance_analysis.sql   # all queries, numbered
├── data/                                    # CSV files go here
└── docs/
    ├── Employee_Performance_Mapping_Report.docx
    ├── employee_sql_queries.docx
    ├── ER_Diagram_png.png                       # ER diagram (MySQL Workbench)
    └── screenshots/                         # query output screenshots
```

## How to Run
1. Install MySQL and MySQL Workbench.
2. Open `sql/employee_performance_analysis.sql` and run the first two lines to create and select the `employee` database.
3. Import the three CSVs using **Table Data Import Wizard** (right-click the schema, then Table Data Import Wizard).
4. Run the analysis queries (sections 3 to 16) one at a time.
5. Run the last section ("ER diagram preparation") to fix data types and add primary/foreign keys.
6. For the ER diagram: **Database → Reverse Engineer**, select the `employee` schema, and export as an image.

## Analysis Performed

| # | Task | SQL concept |
|---|------|-------------|
| 3 | Basic employee details | `SELECT` |
| 4 | Employees by rating (<2, >4, 2–4) | `WHERE`, `BETWEEN` |
| 5 | Full names in Finance | `CONCAT` |
| 6 | Manager / President / CEO | `IN` |
| 7 | Healthcare + Finance employees | `UNION` |
| 8 | Max rating per department | CTE + `JOIN`, `GROUP BY` |
| 9 | Min / max salary per role | Aggregates |
| 10 | Experience ranking | `RANK()` window function |
| 11 | High-salary employees view | `VIEW` |
| 12 | Experience > 10 years | Nested query |
| 13 | Job profile validation | `CASE` |
| 14 | Index on `first_name` | `CREATE INDEX` |
| 15 | Bonus = 5% × salary × rating | Calculated column |
| 16 | Average salary by country and continent | `GROUP BY` |

### Role standards used in query 13
| Experience (years) | Expected role |
|---|---|
| ≤ 2 | Junior Data Scientist |
| > 2 to 5 | Associate Data Scientist |
| > 5 to 10 | Senior Data Scientist |
| > 10 to 12 | Lead Data Scientist |
| > 12 to 16 | Manager |

## Data Types, Keys and Constraints
After the analysis queries, the script prepares the tables for the ER diagram (last part of `sql/employee_performance_analysis.sql`):

- **Data types:** CSV import creates every column as `text`/`int`, so `ALTER TABLE ... MODIFY COLUMN` converts them to `VARCHAR` and `FLOAT`, and `start_date` in `proj_table` is renamed.
- **Unique keys:** `proj_table(proj_id)` and `emp_record_table(emp_id)` are made unique so they can be referenced.
- **Foreign keys:**
  - `emp_record_table.proj_id` references `proj_table.proj_id`
  - `emp_record_table.manager_id` references `emp_record_table.emp_id` (manager is also an employee)
  - `data_science_team.emp_id` references `emp_record_table.emp_id`
- **Data cleaning before adding keys:** employees with `proj_id = 'NA'` are handled, orphan `manager_id` values are set to `NULL`, and Data Science team members missing from `emp_record_table` are inserted so the foreign key does not fail.

## ER Diagram
![ER Diagram](docs/ER_Diagram_png.png)

`emp_record_table` is the central table. `proj_table` links to it through `proj_id`, `data_science_team` links through `emp_id`, and `manager_id` refers back to `emp_id` (self-reference).

## Queries and Results

Each query is followed by its output from MySQL Workbench.

### 1. Create the Database and Import Data
```sql
CREATE DATABASE employee;
USE employee;
-- Data imported using MySQL Workbench Table Data Import Wizard
```
![1. Create the Database and Import Data](docs/screenshots/Solution_no_1.png)

Importing the CSV files with the Table Data Import Wizard:

![Table Data Import Wizard](docs/screenshots/Screenshot__43_.png)

### 2. Entity Relationship Diagram
Created with **Database > Reverse Engineer** in MySQL Workbench (final diagram is shown in the [ER Diagram](#er-diagram) section above).

![Reverse Engineer Database](docs/screenshots/Screenshot_2025-06-07_235847.png)

### 3. Fetch Basic Employee Details
```sql
SELECT emp_id, first_name, last_name, gender, dept FROM emp_record_table;
```
![3. Fetch Basic Employee Details](docs/screenshots/Solution_no_3.png)

### 4(a). Employees with Rating < 2
```sql
SELECT emp_id, first_name, last_name, gender, dept, emp_rating FROM emp_record_table WHERE emp_rating < '2';
```
![4(a). Employees with Rating < 2](docs/screenshots/Solution_no_4_1_.png)

### 4(b). Employees with Rating > 4
```sql
SELECT emp_id, first_name, last_name, gender, dept, emp_rating FROM emp_record_table WHERE emp_rating > '4';
```
![4(b). Employees with Rating > 4](docs/screenshots/Solution_no_4_2_.png)

### 4(c). Employees with Rating between 2 and 4
```sql
SELECT emp_id, first_name, last_name, gender, dept, emp_rating FROM emp_record_table WHERE emp_rating BETWEEN '2' AND '4';
```
![4(c). Employees with Rating between 2 and 4](docs/screenshots/Solution_no_4_3_.png)

### 5. Full Names of Finance Department Employees
```sql
SELECT CONCAT(first_name, ' ', last_name) AS name FROM emp_record_table WHERE dept = 'finance';
```
![5. Full Names of Finance Department Employees](docs/screenshots/Solution_no_5.png)

### 6. Leadership Roles (Manager, President, CEO)
```sql
SELECT emp_id, first_name, role, dept FROM emp_record_table WHERE role IN ('manager','president','CEO');
```
![6. Leadership Roles (Manager, President, CEO)](docs/screenshots/Solution_no_6.png)

### 7. Healthcare and Finance Employees (UNION)
```sql
SELECT * FROM emp_record_table WHERE dept = 'Healthcare' UNION SELECT * FROM emp_record_table WHERE dept = 'Finance';
```
![7. Healthcare and Finance Employees (UNION)](docs/screenshots/Solution_no_7.png)

### 8. Max Rating per Department
```sql
WITH max_rating_per_dept AS (SELECT dept, MAX(emp_rating) AS max_rating FROM emp_record_table GROUP BY dept)
SELECT e.emp_id, e.first_name, e.last_name, e.role, e.dept, e.emp_rating, m.max_rating
FROM emp_record_table e JOIN max_rating_per_dept m ON e.dept = m.dept;
```
![8. Max Rating per Department](docs/screenshots/Solution_no_8.png)

### 9. Min and Max Salary by Role
```sql
SELECT role, MAX(salary) AS max_salary, MIN(salary) AS min_salary FROM emp_record_table GROUP BY role;
```
![9. Min and Max Salary by Role](docs/screenshots/Solution_no_9.png)

### 10. Rank Employees by Experience
```sql
SELECT emp_id, first_name, exp, RANK() OVER (ORDER BY exp DESC) AS experience_rank FROM emp_record_table;
```
![10. Rank Employees by Experience](docs/screenshots/Solution_no_10.png)

### 11. View for High Salary Employees
```sql
CREATE VIEW high_salary_employees AS SELECT * FROM emp_record_table WHERE salary > 6000;
SELECT * FROM high_salary_employees;
```
![11. View for High Salary Employees](docs/screenshots/Solution_no_11.png)

### 12. Nested Query: Experience > 10 Years
```sql
SELECT * FROM emp_record_table WHERE emp_id IN (SELECT emp_id FROM emp_record_table WHERE exp > 10);
```
![12. Nested Query: Experience > 10 Years](docs/screenshots/Solution_no_12.png)

### 13. Job Profile Validation
```sql
SELECT emp_id, first_name, exp, role,
CASE
WHEN exp <= 2 THEN 'Junior Data Scientist'
WHEN exp > 2 AND exp <= 5 THEN 'Associate Data Scientist'
WHEN exp > 5 AND exp <= 10 THEN 'Senior Data Scientist'
WHEN exp > 10 AND exp <= 12 THEN 'Lead Data Scientist'
WHEN exp > 12 AND exp <= 16 THEN 'Manager'
ELSE 'Invalid' END AS stander_role FROM data_science_team;
```
![13. Job Profile Validation](docs/screenshots/Solution_no_13.png)

### 14. Create Index on FIRST_NAME
```sql
CREATE INDEX idx_first_name ON emp_record_table (first_name(100));
SELECT * FROM emp_record_table WHERE first_name = 'eric';
```
![14. Create Index on FIRST_NAME](docs/screenshots/Solution_no_14.png)

### 15. Calculate Bonus (5% of Salary x Rating)
```sql
SELECT emp_id, first_name, salary, emp_rating, (0.05 * salary * emp_rating) AS bonus FROM emp_record_table;
```
![15. Calculate Bonus (5% of Salary x Rating)](docs/screenshots/Solution_no_15.png)

### 16. Average Salary by Country and Continent
```sql
SELECT continent, country, AVG(salary) AS avg_salary FROM emp_record_table GROUP BY continent, country;
```
![16. Average Salary by Country and Continent](docs/screenshots/Solution_no_16.png)

## Key Learnings
- Writing readable analytical SQL with CTEs, window functions and views
- Using `CASE` to validate job roles against experience standards
- Creating an index on a text column to speed up lookups
- Documenting a database project for others to reproduce

## Author
**Kabir Rathore** · [GitHub](https://github.com/kabirrathore004-boop)
