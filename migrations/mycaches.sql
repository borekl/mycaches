-- 1 up
CREATE TABLE finds (
  finds_i INTEGER PRIMARY KEY,
  cacheid TEXT UNIQUE,
  name TEXT NOT NULL,
  difficulty INTEGER CHECK ( difficulty BETWEEN 2 AND 10 ),
  terrain INTEGER CHECK ( terrain BETWEEN 2 AND 10 ),
  prev TEXT,
  found TEXT,
  next TEXT,
  ctype INTEGER,
  favorite INTEGER CHECK ( favorite BETWEEN 0 AND 1 ),
  gallery INTEGER CHECK ( gallery BETWEEN 0 AND 1 ),
  xtf INTEGER CHECK ( xtf BETWEEN 0 and 3 ),
  archived INTEGER CHECK ( archived BETWEEN 0 AND 1 ),
  logid TEXT
);

CREATE TABLE hides (
  hides_i INTEGER PRIMARY KEY,
  cacheid TEXT UNIQUE,
  name TEXT NOT NULL,
  difficulty INTEGER CHECK ( difficulty BETWEEN 2 AND 10 ),
  terrain INTEGER CHECK ( terrain BETWEEN 2 AND 10 ),
  published TEXT,
  finds INTEGER,
  found TEXT,
  ctype INTEGER,
  gallery INTEGER,
  archived INTEGER,
  status INTEGER
);

CREATE TABLE users (
  userid TEXT PRIMARY KEY,
  pw TEXT
);

-- 1 down
drop table if exists finds;
drop table if exists hides;
drop table if exists users;
