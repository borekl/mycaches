-- 1 up
CREATE TABLE finds (
  -- primary key and sequence number
  finds_i INTEGER PRIMARY KEY,
  -- GC code
  cacheid TEXT UNIQUE,
  -- cache name
  name TEXT NOT NULL,
  -- D/T rating times two (ie. 5 is 10, 2.5 is 5 etc.)
  difficulty INTEGER CHECK ( difficulty BETWEEN 2 AND 10 ),
  terrain INTEGER CHECK ( terrain BETWEEN 2 AND 10 ),
  -- date last found before me
  prev TEXT,
  -- date when found
  found TEXT,
  -- date of the next found it log
  next TEXT,
  -- cache type
  ctype INTEGER,
  -- favorite flag
  favorite INTEGER CHECK ( favorite BETWEEN 0 AND 1 ),
  -- photo gallery flag
  gallery INTEGER CHECK ( gallery BETWEEN 0 AND 1 ),
  -- FTF/STF/TTF flag (1,2,3)
  xtf INTEGER CHECK ( xtf BETWEEN 0 and 3 ),
  -- archived
  archived INTEGER CHECK ( archived BETWEEN 0 AND 1 ),
  -- FI log's LUID
  logid TEXT
);

CREATE TABLE hides (
  -- primary key and sequence number
  hides_i INTEGER PRIMARY KEY,
  -- GC code
  cacheid TEXT UNIQUE,
  -- cache name
  name TEXT NOT NULL,
  -- D/T rating times two (ie. 5 is 10, 2.5 is 5 etc.)
  difficulty INTEGER CHECK ( difficulty BETWEEN 2 AND 10 ),
  terrain INTEGER CHECK ( terrain BETWEEN 2 AND 10 ),
  -- publication date
  published TEXT,
  -- number of finds
  finds INTEGER,
  -- date when last found
  found TEXT,
  -- cache type
  ctype INTEGER,
  -- photo gallery flag
  gallery INTEGER,
  -- archived
  archived INTEGER,
  -- status (0-unspecified, 1-active, 2-disabled, 3-in development,
  -- 4-waiting to be placed, 5-waiting for publication, 6-archived)
  status INTEGER
);

CREATE TABLE users (
  -- username
  userid TEXT PRIMARY KEY,
  -- hashed password
  pw TEXT
);

-- 1 down
drop table if exists finds;
drop table if exists hides;
drop table if exists users;


-- 2 up / replace 'archived' with 'status' value of 6
UPDATE hides SET status = 6 WHERE archived = 1;
ALTER TABLE hides DROP COLUMN archived;

ALTER TABLE finds ADD COLUMN status INTEGER;
UPDATE finds SET status = 1;
UPDATE finds SET status = 6 WHERE archived = 1;
ALTER TABLE finds DROP COLUMN archived;

-- 2 down
ALTER TABLE hides ADD COLUMN archived INTEGER;
UPDATE hides SET archived = 1 WHERE status = 6;
UPDATE hides SET status = 0 WHERE status = 6;

ALTER TABLE finds ADD COLUMN archived INTEGER;
UPDATE finds SET archived = 1 WHERE status = 6;
ALTER TABLE finds DROP COLUMN status;


-- 3 up / add new table for tracking log entries
CREATE TABLE logs (
  logs_i INTEGER PRIMARY KEY,
  -- sequence number for ordering the log in case of ties
  seq INTEGER DEFAULT 0,
  -- date of the log entry
  date TEXT NOT NULL,
  -- cache id
  cacheid TEXT NOT NULL,
  -- geocaching nickname of the player
  player TEXT NOT NULL,
  -- log type (1-found it, 2-owner visit, 3-disable, 4-enable, 5-archive)
  logtype INTEGER NOT NULL,
  -- log LUUID
  logid TEXT,
  ---
  FOREIGN KEY (cacheid) REFERENCES hides(cacheid)
);

-- 3 down
DROP TABLE logs;
