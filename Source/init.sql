-- DROP DATABASE planner;
--
-- CREATE DATABASE planner
--     WITH
--     OWNER = "Oper"
--     ENCODING = 'UTF8'
--     LOCALE_PROVIDER = 'libc'
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;

CREATE TYPE result_type AS (
    success BOOLEAN,
    error TEXT,
    error_field TEXT
);
CREATE TYPE user_type AS ENUM ('default', 'moderator');
CREATE TYPE group_type AS ENUM ('all', 'personal', 'default');

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    user_type user_type NOT NULL DEFAULT 'default',
    email varchar UNIQUE NOT NULL CHECK (LENGTH(email) <= 256),
    username varchar UNIQUE NOT NULL CHECK (LENGTH(username) <= 16),
    password varchar CHECK (LENGTH(password) <= 256),
    is_blocked BOOLEAN DEFAULT FALSE
);

CREATE TABLE user_group (
    group_id SERIAL PRIMARY KEY,
    name varchar NOT NULL CHECK (LENGTH(name) <= 256),
    invite_link varchar NOT NULL CHECK (LENGTH(invite_link) <= 256),
    group_type group_type NOT NULL
);

CREATE TABLE group_member (
    group_id INTEGER REFERENCES user_group(group_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    is_creator BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (group_id, user_id)
);

CREATE TABLE subject (
    subject_id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES user_group(group_id) ON DELETE CASCADE,
    creator_id INTEGER DEFAULT 0 REFERENCES users(user_id) ON DELETE SET DEFAULT,
    name varchar NOT NULL CHECK (LENGTH(name) <= 256)
);


CREATE TABLE collection (
    collection_id SERIAL PRIMARY KEY,
    subject_id INTEGER REFERENCES subject(subject_id) ON DELETE CASCADE,
    creator_id INTEGER DEFAULT 0 REFERENCES users(user_id) ON DELETE SET DEFAULT,
    name varchar NOT NULL CHECK (LENGTH(name) <= 256)
);


CREATE TABLE collection_subscriber (
    collection_id INTEGER REFERENCES collection(collection_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    subscription_date TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (collection_id, user_id)
);


CREATE TABLE task (
    task_id SERIAL PRIMARY KEY,
    collection_id INTEGER REFERENCES collection(collection_id) ON DELETE CASCADE,
    name varchar NOT NULL CHECK (LENGTH(name) <= 256),
    description TEXT NOT NULL CHECK (LENGTH(description) <= 5000)
);

CREATE TABLE repeat_interval (
    interval_id SERIAL PRIMARY KEY,
    creator_id INTEGER DEFAULT 0 REFERENCES users(user_id) ON DELETE SET DEFAULT,
    rule VARCHAR NOT NULL,
    index_if_failure VARCHAR NOT NULL
);


CREATE TABLE user_task (
    task_id INTEGER REFERENCES task(task_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    is_creator BOOLEAN DEFAULT FALSE,
    difficulty INTEGER CHECK (difficulty BETWEEN 1 AND 5),
    repeat_interval INTEGER DEFAULT 0 REFERENCES repeat_interval(interval_id) ON DELETE SET DEFAULT,
    is_blocked BOOLEAN DEFAULT FALSE,
    repeat_index INTEGER DEFAULT 0,
    last_repeat_date TIMESTAMP DEFAULT NOW(),
    next_repeat_date TIMESTAMP,
    PRIMARY KEY (task_id, user_id)
);

-- Table solution
CREATE TABLE solution (
    solution_id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES task(task_id) ON DELETE CASCADE,
    creator_id INTEGER DEFAULT 0 REFERENCES users(user_id) ON DELETE SET DEFAULT,
    solution TEXT NOT NULL CHECK (LENGTH(solution) <= 5000)
);

-- Table comment
CREATE TABLE comment (
    comment_id SERIAL PRIMARY KEY,
    solution_id INTEGER REFERENCES solution(solution_id) ON DELETE CASCADE,
    creator_id INTEGER DEFAULT 0 REFERENCES users(user_id) ON DELETE SET DEFAULT,
    text TEXT NOT NULL CHECK (LENGTH(text) <= 1000)
);

