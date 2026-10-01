-- 1. Create the database
create database employee;
use employee;

-- 3. Basic employee details
select emp_id, first_name, last_name, gender, dept from emp_record_table;

-- 4. Employees by rating (<2, >4, between 2 and 4)
select emp_id, first_name, last_name, gender, dept,emp_rating from emp_record_table where emp_rating <'2';
select emp_id, first_name, last_name, gender, dept,emp_rating from emp_record_table where emp_rating >'4';
select emp_id, first_name, last_name, gender, dept,emp_rating from emp_record_table where emp_rating between '2' and '4';

-- 5. Full names of Finance employees
select concat(first_name,' ', last_name) as name from emp_record_table where dept = 'finance';

-- 6. Leadership roles
select emp_id, first_name, role, dept from emp_record_table where role in ('manager','president','CEO');

-- 7. Healthcare and Finance employees (UNION)
select * from emp_record_table where dept = 'Healthcare' union select * from emp_record_table where dept = 'Finance';

-- 8. Max rating per department
with max_rating_per_dept as (select dept, max(emp_rating) as max_rating from emp_record_table group by dept)
select e.emp_id, e.first_name, e.last_name, e.role, e.dept, e.emp_rating, m.max_rating from emp_record_table e
join max_rating_per_dept m on e.dept = m.dept;

-- 9. Min and max salary by role
select role, max(salary) as max_salary, min(salary) as min_salary from emp_record_table group by role;

-- 10. Rank employees by experience
select emp_id, first_name, exp, rank() over (order by exp desc) as experience_rank from emp_record_table;

-- 11. View for high salary employees
create view high_salary_employees as select * from emp_record_table where salary > 6000;
select * from high_salary_employees;

-- 12. Nested query: experience > 10 years
select * from emp_record_table where emp_id in(select emp_id from emp_record_table where exp>10);

-- 13. Job profile validation
select emp_id, first_name, exp, role, case when exp <= 2 then 'Junior Data Scientist'
when exp >2 and exp <= 5 then 'Associate Data Scientist'
when exp >5 and exp <= 10 then 'Senior Data Scientist'
when exp >10 and exp <= 12 then 'Lead Data Scientist'
when exp >12 and exp <= 16 then 'Manager'
else 'Invalid'
end as stander_role from data_science_team;

-- 14. Index on first_name
create index idx_first_name on emp_record_table (first_name(100));
select * from emp_record_table where first_name = 'eric';

-- 15. Bonus = 5% of salary x rating
select emp_id, first_name, salary, emp_rating, (0.05 * salary * emp_rating) as bonus from emp_record_table;

-- 16. Average salary by continent and country
select continent, country, avg(salary) as avg_salary from emp_record_table group by continent, country;

-- ============================================================
-- 2. ER diagram preparation: data types, keys and constraints
-- ============================================================
alter table emp_record_table
modify column emp_Id varchar(10),
modify column first_name varchar(50),
modify column last_name varchar(50),
modify column gender varchar(50),
modify column role varchar(100),
modify column dept varchar(100),
modify column exp float,
modify column salary float,
modify column emp_rating float,
modify column country varchar(50),
modify column continent varchar(50),
modify column manager_id varchar(10),
modify column proj_id varchar(10);
alter table data_science_team
modify column emp_Id varchar(10),
modify column first_name varchar(50),
modify column last_name varchar(50),
modify column gender varchar(50),
modify column role varchar(100),
modify column dept varchar(100),
modify column exp float,
modify column country varchar(50),
modify column continent varchar(50);
describe proj_table;
alter table proj_table
change 'start _date' start_date varchar(10);
alter table proj_table
modify column proj_name varchar(50),
modify column domain varchar(50),
modify column start_date varchar(50),
modify column closure_date varchar(50),
modify column dev_qtr varchar(50),
modify column status varchar(50);
ALTER TABLE emp_record_table
ADD CONSTRAINT fk_project
FOREIGN KEY (proj_id) REFERENCES proj_table(proj_id);
ALTER TABLE proj_table
ADD UNIQUE (proj_id);
SELECT DISTINCT proj_id
FROM emp_record_table
WHERE proj_id IS NOT NULL
AND proj_id NOT IN (
    SELECT proj_id FROM proj_table
);
DELETE FROM emp_record_table
WHERE proj_id = 'NA' OR proj_id IS NULL;
UPDATE emp_record_table
SET proj_id = NULL
WHERE proj_id = 'NA';
INSERT INTO proj_table (proj_id, proj_name, domain, start_date, closure_date, dev_qtr, status)
VALUES ('NA', 'Unassigned', 'Misc', '2020-01-01', '2025-12-31', 'Q4', 'Unknown');
ALTER TABLE emp_record_table
ADD CONSTRAINT fk_manager
FOREIGN KEY (manager_id) REFERENCES emp_record_table(emp_id);
SHOW INDEX FROM emp_record_table;
ALTER TABLE emp_record_table
ADD UNIQUE (emp_id);
SELECT DISTINCT manager_id
FROM emp_record_table
WHERE manager_id IS NOT NULL
AND manager_id NOT IN (
  SELECT emp_id FROM emp_record_table
);
UPDATE emp_record_table
SET manager_id = NULL
WHERE manager_id IS NOT NULL
AND manager_id NOT IN (
  SELECT emp_id FROM (
    SELECT emp_id FROM emp_record_table
  ) AS valid_ids
);
ALTER TABLE data_science_team
ADD CONSTRAINT fk_ds_team_employee
FOREIGN KEY (emp_id) REFERENCES emp_record_table(emp_id);
SELECT DISTINCT emp_id
FROM data_science_team
WHERE emp_id NOT IN (
  SELECT emp_id FROM emp_record_table
);
INSERT INTO emp_record_table (emp_id, first_name, last_name, gender, role, dept, exp, country, continent, salary, emp_rating, manager_id, proj_id)
SELECT emp_id, first_name, last_name, gender, role, dept, exp, country, continent, NULL, NULL, NULL, NULL
FROM data_science_team
WHERE emp_id NOT IN (
  SELECT emp_id FROM emp_record_table
);
