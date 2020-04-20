CREATE TABLE finds (

  -- meaningless primary key
  finds_i INTEGER PRIMARY KEY,

  -- GC code
  cacheid TEXT NOT NULL UNIQUE,

  -- cache name
  name TEXT NOT NULL,

  -- D/T rating times two (ie. 5 is 10, 2.5 is 5 etc.)
  difficulty INTEGER NOT NULL CHECK ( difficulty BETWEEN 1 AND 10 ),
  terrain INTEGER NOT NULL CHECK ( terrain BETWEEN 1 AND 10 ),

  -- date when found
  found TEXT,

  -- date of the next found it log
  next TEXT,

  -- cache type as t-traditional, ?-mystery, m-multicache, w-wherigo,
  -- l-letterbox,L-lab,v-virtual,e-earth,E-event,M-mega,G-giga,C-CITO
  ctype TEXT,
  
  -- favorite flag
  favorite INTEGER,
  
  -- photo gallery partial URL
  gallery TEXT,
  
  -- FTF/STF/TTF flag (1,2,3)
  xtf INTEGER

);

INSERT INTO finds VALUES (
  1,
  'GC2MFHF', 'Pamatne stromy - 1. Dub u nemocnice na Bukove',
  4, 3,
  '2018-07-12', '2018-07-13',
  't',
  0,
  NULL,
  NULL
);
