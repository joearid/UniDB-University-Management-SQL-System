````markdown
# **UniDB – University Management SQL System**  

A PostgreSQL database schema for managing students, courses, enrollments, grades, and surveys with transactional integrity and analytics queries. Ideal for academic management and learning SQL design best practices.  

---

## **Features**

- Structured tables for students, roles, programs, cohorts, courses, grades, and surveys.  
- Transaction-safe enrollment and course registration with capacity/version control.  
- Recursive queries for hierarchical structures (campus → building → room).  
- Analytics queries for top students, average grades, and course capacities.  
- Includes sample data for demonstration and testing purposes.  

---

## **Getting Started**

1. **Clone the repository**:  
```bash
git clone https://github.com/<username>/UniDB.git
cd UniDB
````

2. **Create the database and run the SQL script**:

```sql
CREATE DATABASE university;
\c university
\i database.sql
```

3. **Verify the data** with some example queries:

```sql
SELECT * FROM person;
SELECT * FROM enrollment;
SELECT * FROM grade_transaction;
SELECT * FROM survey;
```

---

## **Project Structure**

```
UniDB/
├── database.sql         # Full PostgreSQL schema + sample data
├── README.md            # Project documentation
```

---

## **Example Queries**

* **Top students per course**

```sql
SELECT student_role_id, course_offering_id, AVG(grade) AS avg_grade
FROM grade_transaction
GROUP BY student_role_id, course_offering_id
ORDER BY avg_grade DESC;
```

* **Recursive place hierarchy**

```sql
WITH RECURSIVE place_tree AS (
    SELECT id, name, outer_place_id, 0 AS depth
    FROM place
    WHERE outer_place_id IS NULL
    UNION ALL
    SELECT p.id, p.name, p.outer_place_id, pt.depth + 1
    FROM place p
    JOIN place_tree pt ON p.outer_place_id = pt.id
)
SELECT * FROM place_tree;
```

* **Course capacity status**

```sql
SELECT c.code, co.semester, co.capacity, co.version
FROM course_offering co
JOIN course c ON co.course_id = c.id;
```

---

## **Skills Demonstrated**

* SQL schema design & normalization
* Transactional integrity with `BEGIN/COMMIT`
* Recursive CTEs for hierarchical data
* Data analytics using grouping, ranking, and averages
* Sample data management and verification

---

## **Notes**

* Tested with PostgreSQL 14+
* No external dependencies required
* Can be extended for university management applications

