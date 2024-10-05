USE Projects_01
GO

SELECT * FROM Employee_Attrition_01;


---Distribution of employees accross departments
CREATE VIEW emp_across_dept
AS
SELECT dept, COUNT(emp_id) as emp_count
FROM Emp_Att
GROUP BY dept
ORDER BY 2;

---attrition rate across departments
CREATE VIEW att_across_dept
AS
SELECT dept, AVG(CAST(time_spend_company AS INT)) AS avg_time_spent
			,ROUND(SUM(CAST(time_spend_company AS INT)) *100/(SELECT SUM(CAST(time_spend_company AS INT)) FROM Emp_Att),2) AS att_rate
FROM Emp_Att
GROUP BY dept

----salary distribution
CREATE VIEW salarydist_across_dept
AS
SELECT salary, dept, COUNT(emp_id) as emp_count
FROM Emp_Att
GROUP BY salary, dept
ORDER BY salary, 3 desc


/*What is the distribution of satisfaction levels among employees?
Are there any patterns or trends in satisfaction levels? 
*/

SELECT * FROM emp_att

SELECT MIN(satisfaction_level) as min_sat
		,MAX(satisfaction_level) as max_sat
FROM emp_att

ALTER TABLE emp_att
ADD sat_cat VARCHAR (10)

ALTER TABLE emp_att
ALTER COLUMN satisfaction_level FLOAT

UPDATE emp_att
SET sat_cat = CASE WHEN satisfaction_level >0.00 AND satisfaction_level <= 0.39 THEN 'Low_sat'
					WHEN satisfaction_level >=0.4 AND satisfaction_level <= 0.69 THEN 'Mid_sat'
					WHEN satisfaction_level >= 0.7 THEN 'High_sat'
					END

/*What is the distribution of satisfaction levels among employees?
Are there any patterns or trends in satisfaction levels? 
*/

---this is used to categorize employees into different satisfaction levels
SELECT sat_cat, COUNT(satisfaction_level) AS sat_cat_count
FROM emp_att
GROUP BY sat_cat


--here we look out for patterns in satisfaction levels
CREATE VIEW sat_cat_across_dept
AS
SELECT dept, salary, sat_cat, COUNT(emp_id) as emp_count
FROM emp_att
GROUP BY dept, salary, sat_cat
ORDER BY dept, salary


---distribution of  employees promotions across dept
CREATE VIEW emp_promo_across_dept
AS
SELECT dept, salary, promotion_last_5years, COUNT(*) AS employee_count
FROM Emp_Att
GROUP BY dept, salary,  promotion_last_5years;

---Explain to your manager what actually leads to differences in income (salary)

SELECT *  FROM Emp_Att;

SELECT dept, number_project, salary, AVG(CAST(average_montly_hours as int)) avg_worktime, count(emp_id) emp_count
FROM Emp_Att
GROUP BY dept, number_project, salary
ORDER BY dept, number_project



--How does the distribution of last evaluation scores look? Is there a correlation between satisfaction level and last evaluation?
CREATE VIEW last_eval_dist
AS
SELECT dept, salary, AVG(last_evaluation) AS last_eval
FROM Emp_Att
GROUP BY dept, salary
ORDER BY dept

/*How many projects are employees typically involved in?
Is there a relationship between the number of projects and average monthly hours worked?
*/

CREATE VIEW proj_no_dist
AS
SELECT number_project, COUNT(emp_id) AS emp_count, AVG(CAST(average_montly_hours as int)) AS avg_mon_hrs
FROM Emp_Att
GROUP BY number_project
ORDER BY 2 DESC

--relationship between no of proj aand monthly hrs worked

CREATE VIEW proj_no_scatt
AS
SELECT dept, number_project AS proj_num_cat, COUNT(emp_id) AS emp_count, SUM(CAST(number_project AS INT)) AS no_of_proj, 
				AVG(CAST(average_montly_hours as int)) AS avg_mon_hrs
FROM Emp_Att
GROUP BY dept, number_project
ORDER BY 2 DESC

---correlation betwwen number of projects and monthly hours worked

DECLARE @N INT, @SumX FLOAT, @SumY FLOAT, @SumXY FLOAT, @SumXSquare FLOAT, @SumYSquare FLOAT;
SELECT 
    @N = COUNT(*),
    @SumX = SUM(CAST(number_project AS INT)),
    @SumY = SUM(CAST(average_montly_hours as int)),
    @SumXY = SUM(CAST(number_project AS INT) * CAST(average_montly_hours as int)),
    @SumXSquare = SUM(CAST(number_project AS INT) * CAST(number_project AS INT)),
    @SumYSquare = SUM(CAST(average_montly_hours as int) * CAST(average_montly_hours as int))
FROM Emp_Att

SELECT 
    (@N * @SumXY - @SumX * @SumY) / SQRT((@N * @SumXSquare - POWER(@SumX, 2)) * (@N * @SumYSquare - POWER(@SumY, 2))) AS CorrelationCoefficient
FROM Emp_Att;


/*How long do employees typically spend in the company?
*/
CREATE VIEW time_spent
AS
SELECT dept, AVG(CAST(time_spend_company AS INT)) AS avg_time_spent
		,ROUND(AVG(satisfaction_level),2) AS avg_sat_level
FROM Emp_Att
GROUP BY dept;

---Is there a correlation between time spent in the company and satisfaction?
DECLARE @N INT, @SumX FLOAT, @SumY FLOAT, @SumXY FLOAT, @SumXSquare FLOAT, @SumYSquare FLOAT;
SELECT 
    @N = COUNT(*),
    @SumX = SUM(CAST(time_spend_company AS INT)),
    @SumY = SUM(CAST(satisfaction_level as int)),
    @SumXY = SUM(CAST(time_spend_company AS INT) * CAST(satisfaction_level as int)),
    @SumXSquare = SUM(CAST(time_spend_company AS INT) * CAST(time_spend_company AS INT)),
    @SumYSquare = SUM(CAST(satisfaction_level as int) * CAST(satisfaction_level as int))
FROM Emp_Att;

SELECT 
    (@N * @SumXY - @SumX * @SumY) / SQRT((@N * @SumXSquare - POWER(@SumX, 2)) * (@N * @SumYSquare - POWER(@SumY, 2))) AS CorrelationCoefficient
FROM Emp_Att;

--time spent across departments
SELECT dept, AVG(CAST(time_spend_company AS INT)) AS avg_time_spent
		,ROUND(AVG(satisfaction_level),2) AS avg_sat_level
FROM Emp_Att
GROUP BY dept

/*How many employees have received promotions in the last 5 years?
Is there a connection between promotions and job satisfaction?*/

SELECT * FROM Emp_Att

---number of employee who received promotions across dept and salary levels
CREATE VIEW emp_promo_dist
AS
SELECT dept, salary, promotion_last_5years, COUNT(emp_id) emp_count
FROM Emp_Att
GROUP BY promotion_last_5years, dept, salary
ORDER BY dept, salary

----Is there a connection between promotions and job satisfaction

SELECT dept, salary, promotion_last_5years, sat_cat, COUNT(emp_id) emp_count
FROM Emp_Att
GROUP BY promotion_last_5years, dept, salary, sat_cat
ORDER BY dept, salary

DECLARE @N INT, @SumX FLOAT, @SumY FLOAT, @SumXY FLOAT, @SumXSquare FLOAT, @SumYSquare FLOAT;
WITH sat_cte
AS 
(
	SELECT dept, salary, sat_cat, COUNT(emp_id) Semp_count
	FROM Emp_Att
	GROUP BY sat_cat, dept, salary
),
job_promo
AS
( 
	SELECT dept, salary, promotion_last_5years AS promo, COUNT(emp_id)emp_count
	FROM Emp_Att
	GROUP BY dept, salary, promotion_last_5years
),
corr_cte
AS
(

	SELECT s.sat_cat, j.promo, SUM(s.semp_count) AS sat_count, SUM(j.emp_count) AS promo_count
	FROM sat_cte s
	JOIN job_promo j
	ON j.dept = s.dept
	AND j.salary = s.salary
	GROUP BY s.sat_cat, j.promo
)
	
SELECT 
    @N = COUNT(*),
    @SumX = SUM(promo_count),
    @SumY = SUM(sat_count),
    @SumXY = SUM(promo_count * sat_count),
    @SumXSquare = SUM(promo_count * promo_count),
    @SumYSquare = SUM(sat_count * sat_count)
FROM corr_cte

SELECT 
    (@N * @SumXY - @SumX * @SumY) / SQRT((@N * @SumXSquare - POWER(@SumX, 2)) * (@N * @SumYSquare - POWER(@SumY, 2))) AS CorrelationCoefficient
FROM (SELECT 1) AS dummy;


SELECT * FROM Emp_Att

