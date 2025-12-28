
-- =====================================================
-- SCHEMA
-- =====================================================
CREATE SCHEMA IF NOT EXISTS university;
SET search_path TO university;

-- =====================================================
-- TABLES
-- =====================================================
CREATE TABLE person (
    id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
);

CREATE TABLE role (
    id SERIAL PRIMARY KEY,
    person_id INT NOT NULL REFERENCES person(id),
    role_type TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    CHECK (end_date IS NULL OR end_date > start_date)
);

CREATE TABLE program (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    total_credits INT NOT NULL
);

CREATE TABLE cohort (
    id SERIAL PRIMARY KEY,
    program_id INT NOT NULL REFERENCES program(id),
    start_year INT NOT NULL,
    end_year INT NOT NULL,
    status TEXT NOT NULL,
    version INT NOT NULL DEFAULT 0,
    capacity INT NOT NULL DEFAULT 30
);

CREATE TABLE enrollment (
    id SERIAL PRIMARY KEY,
    student_role_id INT NOT NULL REFERENCES role(id),
    cohort_id INT NOT NULL REFERENCES cohort(id),
    enrolled_at TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (student_role_id, cohort_id)
);

CREATE TABLE place (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    place_type TEXT NOT NULL,
    outer_place_id INT REFERENCES place(id)
);

CREATE TABLE course (
    id SERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    credits INT NOT NULL
);

CREATE TABLE course_offering (
    id SERIAL PRIMARY KEY,
    course_id INT NOT NULL REFERENCES course(id),
    cohort_id INT NOT NULL REFERENCES cohort(id),
    semester TEXT NOT NULL,
    capacity INT NOT NULL,
    version INT NOT NULL DEFAULT 0
);

CREATE TABLE course_registration (
    id SERIAL PRIMARY KEY,
    student_role_id INT NOT NULL REFERENCES role(id),
    registered_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE course_registration_item (
    registration_id INT NOT NULL REFERENCES course_registration(id),
    course_offering_id INT NOT NULL REFERENCES course_offering(id),
    PRIMARY KEY (registration_id, course_offering_id)
);

CREATE TABLE grade_transaction (
    id SERIAL PRIMARY KEY,
    student_role_id INT NOT NULL REFERENCES role(id),
    course_offering_id INT NOT NULL REFERENCES course_offering(id),
    grade NUMERIC(4,2),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE grade_revision (
    id SERIAL PRIMARY KEY,
    original_grade_id INT NOT NULL REFERENCES grade_transaction(id),
    new_grade NUMERIC(4,2) NOT NULL,
    revised_at TIMESTAMP NOT NULL DEFAULT now(),
    reason TEXT
);

CREATE TABLE survey (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL
);

CREATE TABLE survey_version (
    id SERIAL PRIMARY KEY,
    survey_id INT NOT NULL REFERENCES survey(id),
    version_number INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE survey_section (
    id SERIAL PRIMARY KEY,
    survey_version_id INT NOT NULL REFERENCES survey_version(id),
    title TEXT NOT NULL
);

CREATE TABLE survey_question (
    id SERIAL PRIMARY KEY,
    section_id INT NOT NULL REFERENCES survey_section(id),
    question_text TEXT NOT NULL
);

CREATE TABLE survey_submission (
    id SERIAL PRIMARY KEY,
    student_role_id INT NOT NULL REFERENCES role(id),
    survey_version_id INT NOT NULL REFERENCES survey_version(id),
    submitted_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE survey_answer (
    submission_id INT NOT NULL REFERENCES survey_submission(id),
    question_id INT NOT NULL REFERENCES survey_question(id),
    answer TEXT NOT NULL,
    PRIMARY KEY (submission_id, question_id)
);

CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE course_category (
    course_id INT NOT NULL REFERENCES course(id),
    category_id INT NOT NULL REFERENCES category(id),
    PRIMARY KEY (course_id, category_id)
);

-- =====================================================
-- SAMPLE DATA
-- =====================================================
INSERT INTO person (full_name, email) VALUES
('Alice Smith', 'alice@uni.edu'),
('Bob Jones', 'bob@uni.edu');

INSERT INTO role (person_id, role_type, start_date)
VALUES
(1, 'STUDENT', '2022-09-01'),
(2, 'STUDENT', '2022-09-01');

INSERT INTO program (name, total_credits)
VALUES ('Computer Science', 180);

INSERT INTO cohort (program_id, start_year, end_year, status, capacity)
VALUES (1, 2022, 2025, 'ACTIVE', 10);

INSERT INTO place (name, place_type) VALUES
('Beirut Campus', 'CAMPUS');

INSERT INTO place (name, place_type, outer_place_id) VALUES
('Engineering Building', 'BUILDING', 1),
('Room 301', 'ROOM', 2);

-- =====================================================
-- ENROLLMENT TRANSACTION
-- =====================================================
BEGIN;

WITH updated AS (
    UPDATE cohort
    SET capacity = capacity - 1,
        version = version + 1
    WHERE id = 1
      AND capacity > 0
      AND version = 0
    RETURNING id
)
INSERT INTO enrollment (student_role_id, cohort_id)
SELECT 1, id FROM updated;

COMMIT;


-- =====================================================
-- INSERT COURSE & OFFERING
-- =====================================================
INSERT INTO course (code, title, credits)
VALUES ('CS101', 'Introduction to Computer Science', 6);

INSERT INTO course_offering (course_id, cohort_id, semester, capacity)
VALUES (currval('course_id_seq'), 1, 'Fall 2024', 10);

-- =====================================================
-- COURSE REGISTRATION TRANSACTION
-- =====================================================
BEGIN;

WITH updated AS (
    UPDATE course_offering
    SET capacity = capacity - 1,
        version = version + 1
    WHERE id = currval('course_offering_id_seq')
      AND capacity > 0
      AND version = 0
    RETURNING id
),
reg AS (
    INSERT INTO course_registration (student_role_id)
    SELECT 1 FROM updated
    RETURNING id
)
INSERT INTO course_registration_item
SELECT reg.id, updated.id
FROM reg, updated;

COMMIT;


-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
SELECT * FROM person;
SELECT * FROM role;
SELECT * FROM program;
SELECT * FROM cohort;
SELECT * FROM enrollment;
SELECT * FROM place;
SELECT * FROM course;
SELECT * FROM course_offering;
SELECT * FROM course_registration;
SELECT * FROM course_registration_item;



--part2
-- =====================================================
-- GRADE TRANSACTIONS
-- =====================================================
INSERT INTO grade_transaction (student_role_id, course_offering_id, grade)
VALUES (1, currval('course_offering_id_seq'), 95.0);

-- =====================================================
-- GRADE REVISION
-- =====================================================
INSERT INTO grade_revision (original_grade_id, new_grade, reason)
VALUES (currval('grade_transaction_id_seq'), 97.0, 'Re-evaluation of assignment 1');

-- =====================================================
-- SURVEY CREATION
-- =====================================================
INSERT INTO survey (title) VALUES ('Course Feedback');

INSERT INTO survey_version (survey_id, version_number)
VALUES (currval('survey_id_seq'), 1);

INSERT INTO survey_section (survey_version_id, title)
VALUES (currval('survey_version_id_seq'), 'General Feedback');

INSERT INTO survey_question (section_id, question_text)
VALUES (currval('survey_section_id_seq'), 'How do you rate this course overall?');

-- =====================================================
-- SURVEY SUBMISSION
-- =====================================================
INSERT INTO survey_submission (student_role_id, survey_version_id)
VALUES (1, currval('survey_version_id_seq'));

INSERT INTO survey_answer (submission_id, question_id, answer)
VALUES (currval('survey_submission_id_seq'), currval('survey_question_id_seq'), 'Excellent');

-- =====================================================
-- CATEGORY & COURSE CATEGORY
-- =====================================================
INSERT INTO category (name)
VALUES ('Computer Science');

INSERT INTO course_category (course_id, category_id)
VALUES (currval('course_id_seq'), currval('category_id_seq'));

-- =====================================================
-- RECURSIVE PLACE TREE QUERY
-- =====================================================
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

-- =====================================================
-- TOP STUDENTS PER COURSE
-- =====================================================
SELECT *
FROM (
    SELECT
        g.student_role_id,
        g.course_offering_id,
        AVG(g.grade) AS avg_grade,
        ROW_NUMBER() OVER (
            PARTITION BY g.course_offering_id
            ORDER BY AVG(g.grade) DESC
        ) AS rank
    FROM grade_transaction g
    GROUP BY g.student_role_id, g.course_offering_id
) ranked
WHERE rank <= 3;

-- =====================================================
-- VERIFICATION QUERIES PART 2
-- =====================================================
SELECT * FROM grade_transaction;
SELECT * FROM grade_revision;
SELECT * FROM survey;
SELECT * FROM survey_version;
SELECT * FROM survey_section;
SELECT * FROM survey_question;
SELECT * FROM survey_submission;
SELECT * FROM survey_answer;
SELECT * FROM category;
SELECT * FROM course_category;



-- =====================================================
-- ADDITIONAL COURSES & OFFERINGS
-- =====================================================
INSERT INTO course (code, title, credits)
VALUES 
('CS102', 'Data Structures', 6),
('CS103', 'Algorithms', 6),
('CS104', 'Databases', 6);

INSERT INTO course_offering (course_id, cohort_id, semester, capacity)
VALUES 
(currval('course_id_seq') - 3, 1, 'Spring 2025', 10),
(currval('course_id_seq') - 2, 1, 'Spring 2025', 10),
(currval('course_id_seq') - 1, 1, 'Spring 2025', 10);

-- =====================================================
-- MULTIPLE STUDENT REGISTRATIONS
-- =====================================================
INSERT INTO role (person_id, role_type, start_date)
VALUES (1, 'STUDENT', '2023-09-01'),
       (2, 'STUDENT', '2023-09-01');

INSERT INTO enrollment (student_role_id, cohort_id)
VALUES (3, 1),
       (4, 1);

-- =====================================================
-- COURSE REGISTRATION TRANSACTIONS FOR MULTIPLE STUDENTS
-- =====================================================
BEGIN;

-- Student 3 registers for CS102
UPDATE course_offering
SET capacity = capacity - 1,
    version = version + 1
WHERE id = currval('course_offering_id_seq') - 2
  AND capacity > 0
  AND version = 0;

INSERT INTO course_registration (student_role_id)
VALUES (3);

INSERT INTO course_registration_item
VALUES (currval('course_registration_id_seq'), currval('course_offering_id_seq') - 2);

-- Student 4 registers for CS103
UPDATE course_offering
SET capacity = capacity - 1,
    version = version + 1
WHERE id = currval('course_offering_id_seq') - 1
  AND capacity > 0
  AND version = 0;

INSERT INTO course_registration (student_role_id)
VALUES (4);

INSERT INTO course_registration_item
VALUES (currval('course_registration_id_seq'), currval('course_offering_id_seq') - 1);

COMMIT;

-- =====================================================
-- MORE GRADE TRANSACTIONS
-- =====================================================
INSERT INTO grade_transaction (student_role_id, course_offering_id, grade)
VALUES 
(3, currval('course_offering_id_seq') - 2, 88.0),
(4, currval('course_offering_id_seq') - 1, 92.0);

-- =====================================================
-- ADDITIONAL SURVEYS
-- =====================================================
INSERT INTO survey (title) VALUES ('Lab Feedback');

INSERT INTO survey_version (survey_id, version_number)
VALUES (currval('survey_id_seq'), 1);

INSERT INTO survey_section (survey_version_id, title)
VALUES (currval('survey_version_id_seq'), 'Lab Experience');

INSERT INTO survey_question (section_id, question_text)
VALUES (currval('survey_section_id_seq'), 'How useful was the lab session?');

-- Student 3 submission
INSERT INTO survey_submission (student_role_id, survey_version_id)
VALUES (3, currval('survey_version_id_seq'));

INSERT INTO survey_answer (submission_id, question_id, answer)
VALUES (currval('survey_submission_id_seq'), currval('survey_question_id_seq'), 'Very Useful');

-- Student 4 submission
INSERT INTO survey_submission (student_role_id, survey_version_id)
VALUES (4, currval('survey_version_id_seq'));

INSERT INTO survey_answer (submission_id, question_id, answer)
VALUES (currval('survey_submission_id_seq'), currval('survey_question_id_seq'), 'Moderately Useful');

-- =====================================================
-- COMPLEX QUERY: STUDENT PERFORMANCE
-- =====================================================
SELECT 
    r.person_id,
    c.code AS course_code,
    AVG(g.grade) AS average_grade
FROM grade_transaction g
JOIN course_offering co ON g.course_offering_id = co.id
JOIN course c ON co.course_id = c.id
JOIN role r ON g.student_role_id = r.id
GROUP BY r.person_id, c.code
ORDER BY average_grade DESC;

-- =====================================================
-- COMPLEX QUERY: COURSE CAPACITY STATUS
-- =====================================================
SELECT c.code, co.semester, co.capacity, co.version
FROM course_offering co
JOIN course c ON co.course_id = c.id;

-- =====================================================
-- VERIFICATION QUERIES PART 3
-- =====================================================
SELECT * FROM course;
SELECT * FROM course_offering;
SELECT * FROM course_registration;
SELECT * FROM course_registration_item;
SELECT * FROM grade_transaction;
SELECT * FROM survey;
SELECT * FROM survey_version;
SELECT * FROM survey_section;
SELECT * FROM survey_question;
SELECT * FROM survey_submission;
SELECT * FROM survey_answer;



-- =====================================================
-- PART 4: ADDITIONAL STUDENTS, COURSES, REGISTRATIONS, AND CATEGORIES
-- =====================================================

-- -----------------------------
-- 1. ADDITIONAL STUDENTS
-- -----------------------------
INSERT INTO person (full_name, email) VALUES
('Eve Adams', 'eve@uni.edu'),
('Frank Miller', 'frank@uni.edu')
ON CONFLICT (email) DO NOTHING
RETURNING id;

-- -----------------------------
-- 2. ADD STUDENT ROLES
-- -----------------------------
INSERT INTO role (person_id, role_type, start_date)
SELECT id, 'STUDENT', '2024-09-01' FROM person
WHERE email IN ('eve@uni.edu','frank@uni.edu')
ON CONFLICT DO NOTHING
RETURNING id;

-- -----------------------------
-- 3. ENROLL ADDITIONAL STUDENTS INTO COHORT
-- -----------------------------
INSERT INTO enrollment (student_role_id, cohort_id)
SELECT r.id, 1
FROM role r
JOIN person p ON r.person_id = p.id
WHERE p.email IN ('eve@uni.edu','frank@uni.edu')
ON CONFLICT (student_role_id, cohort_id) DO NOTHING;

-- -----------------------------
-- 4. ADDITIONAL COURSES
-- -----------------------------
INSERT INTO course (code, title, credits) VALUES
('CS105', 'Operating Systems', 6),
('CS106', 'Computer Networks', 6),
('CS107', 'Software Engineering', 6)
ON CONFLICT (code) DO NOTHING
RETURNING id;

-- -----------------------------
-- 5. ADD COURSE OFFERINGS
-- -----------------------------
INSERT INTO course_offering (course_id, cohort_id, semester, capacity)
SELECT id, 1, 'Fall 2025', 10 FROM course
WHERE code IN ('CS105','CS106','CS107')
ON CONFLICT DO NOTHING
RETURNING id;

-- -----------------------------
-- 6. COURSE REGISTRATIONS
-- -----------------------------
-- Eve registers for CS105 and CS106
INSERT INTO course_registration (student_role_id)
SELECT r.id FROM role r
JOIN person p ON r.person_id = p.id
WHERE p.email='eve@uni.edu'
RETURNING id;

INSERT INTO course_registration_item (registration_id, course_offering_id)
SELECT cr.id, co.id
FROM course_registration cr
JOIN role r ON cr.student_role_id = r.id
JOIN person p ON r.person_id = p.id
JOIN course_offering co ON co.course_id IN (
    SELECT id FROM course WHERE code IN ('CS105','CS106')
)
WHERE p.email='eve@uni.edu'
ON CONFLICT (registration_id, course_offering_id) DO NOTHING;

-- Frank registers for CS106 and CS107
INSERT INTO course_registration (student_role_id)
SELECT r.id FROM role r
JOIN person p ON r.person_id = p.id
WHERE p.email='frank@uni.edu'
RETURNING id;

INSERT INTO course_registration_item (registration_id, course_offering_id)
SELECT cr.id, co.id
FROM course_registration cr
JOIN role r ON cr.student_role_id = r.id
JOIN person p ON r.person_id = p.id
JOIN course_offering co ON co.course_id IN (
    SELECT id FROM course WHERE code IN ('CS106','CS107')
)
WHERE p.email='frank@uni.edu'
ON CONFLICT (registration_id, course_offering_id) DO NOTHING;

-- -----------------------------
-- 7. ADDITIONAL CATEGORIES
-- -----------------------------
INSERT INTO category (name) VALUES
('Systems'), 
('Networking'),
('Software Engineering')
ON CONFLICT (name) DO NOTHING;

-- -----------------------------
-- 8. ASSIGN COURSES TO CATEGORIES
-- -----------------------------
INSERT INTO course_category (course_id, category_id)
SELECT c.id, cat.id
FROM course c
JOIN category cat ON cat.name='Systems'
WHERE c.code='CS105'
ON CONFLICT (course_id, category_id) DO NOTHING;

INSERT INTO course_category (course_id, category_id)
SELECT c.id, cat.id
FROM course c
JOIN category cat ON cat.name='Networking'
WHERE c.code='CS106'
ON CONFLICT (course_id, category_id) DO NOTHING;

INSERT INTO course_category (course_id, category_id)
SELECT c.id, cat.id
FROM course c
JOIN category cat ON cat.name='Software Engineering'
WHERE c.code='CS107'
ON CONFLICT (course_id, category_id) DO NOTHING;

-- -----------------------------
-- 9. GRADE TRANSACTIONS FOR NEW STUDENTS
-- -----------------------------
INSERT INTO grade_transaction (student_role_id, course_offering_id, grade)
SELECT r.id, co.id, 90.0
FROM role r
JOIN person p ON r.person_id = p.id
JOIN course_offering co ON co.course_id = (
    SELECT id FROM course WHERE code='CS105'
)
WHERE p.email='eve@uni.edu';

INSERT INTO grade_transaction (student_role_id, course_offering_id, grade)
SELECT r.id, co.id, 88.0
FROM role r
JOIN person p ON r.person_id = p.id
JOIN course_offering co ON co.course_id = (
    SELECT id FROM course WHERE code='CS107'
)
WHERE p.email='frank@uni.edu';

-- -----------------------------
-- 10. VERIFICATION QUERIES PART 4
-- -----------------------------
SELECT * FROM person;
SELECT * FROM role;
SELECT * FROM enrollment;
SELECT * FROM course;
SELECT * FROM course_offering;
SELECT * FROM course_registration;
SELECT * FROM course_registration_item;
SELECT * FROM grade_transaction;
SELECT * FROM category;
SELECT * FROM course_category;

