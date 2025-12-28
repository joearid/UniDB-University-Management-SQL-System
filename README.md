# **UniDB – University Management SQL System**

A PostgreSQL database schema for managing students, courses, enrollments, grades, and surveys with transactional integrity and analytics queries.


## **Features**

* Tables for students, roles, programs, cohorts, courses, grades, and surveys.
* Transaction-safe enrollment and registration with capacity/version control.
* Recursive queries for hierarchical structures (campus → building → room).
* Analytics queries for top students, average grades, and course capacity.
* Sample data included for demonstration.



## **Getting Started**

1. Clone the repo:

git clone https://github.com/<username>/UniDB.git
cd UniDB


2. Create the database and run the SQL script:


CREATE DATABASE university;
\c university
\i database.sql


3. Verify with queries, e.g.:

SELECT * FROM person;
SELECT * FROM enrollment;
SELECT * FROM grade_transaction;


## **Project Structure**

UniDB/
├── database.sql
└── README.md
