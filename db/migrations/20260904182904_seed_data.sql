-- migrate:up

-- Seed users, profiles, projects, tasks, and project members
WITH inserted_users AS (
  INSERT INTO users (email, full_name, password_hash)
  VALUES
    ('john@example.com', 'John Doe', 'hash1'),
    ('jane@example.com', 'Jane Smith', 'hash2'),
    ('bob@example.com', 'Bob Wilson', 'hash3'),
    ('alice@example.com', 'Alice Brown', 'hash4')
  RETURNING id, email
),
inserted_profiles AS (
  INSERT INTO user_profiles (user_id, avatar_url, bio, phone)
  SELECT
    id,
    'https://example.com/avatar' ||
      ROW_NUMBER() OVER (ORDER BY email) ||
      '.jpg',
    CASE
      WHEN email LIKE 'john%' THEN 'Project Manager with 5 years experience'
      WHEN email LIKE 'jane%' THEN 'Senior Developer'
      WHEN email LIKE 'bob%' THEN 'UX Designer'
      ELSE 'Business Analyst'
    END,
    '+123456789' || ROW_NUMBER() OVER (ORDER BY email)
  FROM inserted_users
  RETURNING user_id
),
inserted_projects AS (
  INSERT INTO projects (name, description, status, owner_id)
  SELECT
    project.name,
    project.description,
    project.status,
    owner.id
  FROM (
    VALUES
      (
        'Website Redesign',
        'Complete overhaul of company website',
        'active'::project_status,
        'john@example.com'
      ),
      (
        'Mobile App Development',
        'New mobile app for customers',
        'active'::project_status,
        'jane@example.com'
      ),
      (
        'Database Migration',
        'Migrate legacy database to new system',
        'active'::project_status,
        'john@example.com'
      )
  ) AS project(name, description, status, owner_email)
  JOIN inserted_users AS owner
    ON owner.email = project.owner_email
  RETURNING id, name
),
inserted_tasks AS (
  INSERT INTO tasks (
    project_id,
    title,
    description,
    priority,
    status,
    due_date,
    assigned_to
  )
  SELECT
    project.id,
    task.title,
    task.description,
    task.priority,
    task.status,
    task.due_date,
    assignee.id
  FROM (
    VALUES
      (
        'Website Redesign',
        'Create Wireframes',
        'Create wireframes for the redesigned website',
        2,
        'pending'::task_status,
        '2024-03-15'::DATE,
        'bob@example.com'
      ),
      (
        'Website Redesign',
        'Implement Homepage',
        'Build the new homepage design',
        1,
        'in_progress'::task_status,
        '2024-04-01'::DATE,
        'jane@example.com'
      ),
      (
        'Mobile App Development',
        'User Authentication',
        'Implement user sign-up and login',
        1,
        'pending'::task_status,
        '2024-04-10'::DATE,
        'jane@example.com'
      ),
      (
        'Mobile App Development',
        'API Integration',
        'Connect the mobile app to backend APIs',
        2,
        'pending'::task_status,
        '2024-04-30'::DATE,
        'bob@example.com'
      ),
      (
        'Database Migration',
        'Data Analysis',
        'Analyze current database structure',
        2,
        'completed'::task_status,
        '2024-03-25'::DATE,
        'alice@example.com'
      ),
      (
        'Database Migration',
        'Migration Script',
        'Write data migration scripts',
        1,
        'in_progress'::task_status,
        '2024-04-20'::DATE,
        'jane@example.com'
      )
  ) AS task(
    project_name,
    title,
    description,
    priority,
    status,
    due_date,
    assignee_email
  )
  JOIN inserted_projects AS project
    ON project.name = task.project_name
  JOIN inserted_users AS assignee
    ON assignee.email = task.assignee_email
  RETURNING id
),
inserted_members AS (
  INSERT INTO project_members (project_id, user_id, role)
  SELECT
    project.id,
    user_record.id,
    member.role::member_role
  FROM (
    VALUES
      ('Website Redesign', 'john@example.com', 'owner'),
      ('Website Redesign', 'jane@example.com', 'member'),
      ('Website Redesign', 'bob@example.com', 'member'),
      ('Mobile App Development', 'jane@example.com', 'owner'),
      ('Mobile App Development', 'bob@example.com', 'admin'),
      ('Mobile App Development', 'alice@example.com', 'member'),
      ('Database Migration', 'john@example.com', 'owner'),
      ('Database Migration', 'jane@example.com', 'member'),
      ('Database Migration', 'alice@example.com', 'admin')
  ) AS member(project_name, user_email, role)
  JOIN inserted_projects AS project
    ON project.name = member.project_name
  JOIN inserted_users AS user_record
    ON user_record.email = member.user_email
  RETURNING project_id, user_id
)
SELECT COUNT(*) AS project_members_created
FROM inserted_members;


-- migrate:down

-- clear all data
TRUNCATE TABLE project_members CASCADE;
TRUNCATE TABLE tasks CASCADE;
TRUNCATE TABLE projects CASCADE;
TRUNCATE TABLE user_profiles CASCADE;
TRUNCATE TABLE users CASCADE;
