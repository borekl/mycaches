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

  -- status (0-unspecified, 1-active,2-disabled,3-in development,
  -- 4-waiting to be placed,5-waiting for publication)
  status INTEGER
);
