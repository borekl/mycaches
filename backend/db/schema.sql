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

  -- cache type as t-traditional, ?-mystery, m-multicache, w-wherigo,
  -- l-letterbox,L-lab,v-virtual,e-earth,E-event,M-mega,G-giga,C-CITO
  ctype TEXT,
  
  -- favorite flag
  favorite INTEGER,
  
  -- photo gallery flag
  gallery INTEGER,
  
  -- FTF/STF/TTF flag (1,2,3)
  xtf INTEGER,

  -- archived
  archived INTEGER,

  -- FI log's LUID
  logid TEXT

);
