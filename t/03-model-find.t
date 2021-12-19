#!/usr/bin/perl

# Test MyCaches::Model::Find

use utf8;
use Mojo::Base -strict;
use Test::Mojo;
use Test::Most;
use Path::Tiny qw(tempfile);
use MyCaches::Model::Find;

my $t = Test::Mojo->new('MyCaches', { dbfile => tempfile });

# instance creation, default
my $c = MyCaches::Model::Find->new;
isa_ok($c, 'MyCaches::Model::Find');
cmp_deeply($c, methods(
 prev => undef,
 found => undef,
 next => undef,
 favorite => 0,
 xtf => 0,
 logid => undef,
 age => undef,
 held => undef,
));

# instance creation, non-default
$c = MyCaches::Model::Find->new(
  prev => '2019-01-19',
  found => '2019-01-19',
  next => '2019-01-19',
  favorite => 1,
  xtf => 1,
  logid => 'abcdef-012',
);
my $tz = quotemeta $c->tz;
isa_ok($c, 'MyCaches::Model::Find');
cmp_deeply($c, methods(
 prev => Time::Moment->from_string('2019-01-19T00:00' . $c->tz),
 found => Time::Moment->from_string('2019-01-19T00:00' . $c->tz),
 next => Time::Moment->from_string('2019-01-19T00:00' . $c->tz),
 favorite => 1,
 xtf => 1,
 logid => 'abcdef-012',
 age => { years => 0, days => 0, rdays => 0 },
 held => { years => 0, days => 0, rdays => 0 },
));

# instance creation, non-default, from db entry
$c = MyCaches::Model::Find->new(
  entry => {
    cacheid => 'GC9ABCD',
    name => 'Žluťoučký kůň 🐴',
    difficulty => 10,
    terrain => 9,
    ctype => 4,
    gallery => 1,
    status => 1,
    finds_i => 123,
    prev => '2019-01-19',
    found => '2019-01-19',
    next => '2019-01-19',
    favorite => 1,
    xtf => 1,
    logid => 'abcdef-012',
  }
);
isa_ok($c, 'MyCaches::Model::Find');
cmp_deeply($c, methods(
 prev => Time::Moment->from_string('2019-01-19T00:00' . $c->tz),
 found => Time::Moment->from_string('2019-01-19T00:00' . $c->tz),
 next => Time::Moment->from_string('2019-01-19T00:00' . $c->tz),
 favorite => 1,
 xtf => 1,
 logid => 'abcdef-012',
 age => { years => 0, days => 0, rdays => 0 },
 held => { years => 0, days => 0, rdays => 0 },
));

# export of attributes
{
  my $h = $c->to_hash;
  cmp_deeply($h, superhashof({
    finds_i => $c->id,
    prev => $c->prev->strftime('%F'),
    found => $c->found->strftime('%F'),
    next => $c->next->strftime('%F'),
    favorite => $c->xtf,
    xtf => $c->xtf,
    logid => $c->logid,
    age => $c->age,
    held => $c->held,
  }));
}

# export of attributes for db
{
  my $h = $c->to_hash(db => 1);
  ok(!exists $h->{age}, q{Attribute 'age' export suppression});
  ok(!exists $h->{held}, q{Attribute 'held' export suppression});
}

# instance creation, ingestion of alternate date format
$c = MyCaches::Model::Find->new(
  prev => '1/1/2019',
  found => '19/10/2019',
  next => '01/01/2020',
);
isa_ok($c, 'MyCaches::Model::Find');
like($c->prev->to_string, qr/^2019-01-01T.*$tz$/, q{Attribute 'prev' alt value});
like($c->found->to_string, qr/^2019-10-19T.*$tz$/, q{Attribute 'found' alt value});
like($c->next->to_string, qr/^2020-01-01T.*$tz$/, q{Attribute 'next' alt value});

# testing date arithmetic
$c = MyCaches::Model::Find->new(
  prev => '2019-01-19',
  found => '2019-01-20',
  next => '2019-01-21',
);
isa_ok($c, 'MyCaches::Model::Find');
cmp_deeply($c->age, { years => 0, days => 1, rdays => 1 });
cmp_deeply($c->held, { years => 0, days => 1, rdays => 1 });

$c = MyCaches::Model::Find->new(
  prev => '2019-12-31',
  found => '2020-12-31',
  next => '2022-01-01',
);
isa_ok($c, 'MyCaches::Model::Find');
cmp_deeply($c->age, { years => 1, days => 366, rdays => 0 });
cmp_deeply($c->held, { years => 1, days => 366, rdays => 1 });

# special cases: FTF today; age should be undefined and held should be 0
$c = MyCaches::Model::Find->new(
  found => $c->now,
);
isa_ok($c, 'MyCaches::Model::Find');
is($c->age, undef, 'Special case 1: FTF find / age');
cmp_deeply(
  $c->held,
  { years => 0, days => 0, rdays => 0 },
  'Special case 1: FTF find / held'
);

# special cases: FTF 100 days ago; age should be undefined and held should be
# 100
$c = MyCaches::Model::Find->new(
  found => $c->now->plus_days(-100),
);
isa_ok($c, 'MyCaches::Model::Find');
is($c->age, undef, 'Special case 2: FTF find / age');
cmp_deeply(
  $c->held,
  { years => 0, days => 100, rdays => 100 },
  'Special case 2: FTF find / held'
);

# special cases: no next find ("held")
$c = MyCaches::Model::Find->new(
  prev => $c->now->plus_days(-200),
  found => $c->now->plus_days(-100),
);
isa_ok($c, 'MyCaches::Model::Find');
cmp_deeply(
  $c->age,
  { years => 0, days => 100, rdays => 100 },
  'Special case 3: Held find / age'
);
cmp_deeply(
  $c->held,
  { years => 0, days => 100, rdays => 100 },
  'Special case 3: Held find / held'
);

#--- database operations -------------------------------------------------------

# create an entry
$c = MyCaches::Model::Find->new(
  db => $t->app->sqlite->db,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  status => 1,
  prev => '2019-01-19',
  found => '2019-01-19',
  next => '2019-01-19',
  favorite => 1,
  xtf => 1,
  logid => 'abcdef-012',
);
isa_ok($c, 'MyCaches::Model::Find');
lives_ok { $c->create } 'Create entry';
is($c->id, 1, 'New entry row id');

# load the entry by row id
my $d = MyCaches::Model::Find->new(
  db => $t->app->sqlite->db,
  load => { id => $c->id }
);
isa_ok($d, 'MyCaches::Model::Find');
cmp_deeply($d, methods(
  id => 1,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  status => 1,
  prev => Time::Moment->from_string('2019-01-19T00:00' . $d->tz),
  found => Time::Moment->from_string('2019-01-19T00:00' . $d->tz),
  next => Time::Moment->from_string('2019-01-19T00:00' . $d->tz),
  favorite => 1,
  xtf => 1,
  logid => 'abcdef-012',
  age => { years => 0, days => 0, rdays => 0 },
  held => { years => 0, days => 0, rdays => 0 },
));

# load the entry by cache id
$d = MyCaches::Model::Find->new(
  db => $t->app->sqlite->db,
  load => { cacheid => 'GC9ABCD' }
);
isa_ok($d, 'MyCaches::Model::Find');
cmp_deeply($d, methods(
  id => 1,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  status => 1,
  prev => Time::Moment->from_string('2019-01-19T00:00' . $d->tz),
  found => Time::Moment->from_string('2019-01-19T00:00' . $d->tz),
  next => Time::Moment->from_string('2019-01-19T00:00' . $d->tz),
  favorite => 1,
  xtf => 1,
  logid => 'abcdef-012',
  age => { years => 0, days => 0, rdays => 0 },
  held => { years => 0, days => 0, rdays => 0 },
));

# check finding the next row id
$d->get_new_id;
is($d->id, 2, 'Getting new rowid');

# update
$c->{name} = 'Pěl ďábelské ódy'; # bypassing r/o accessor
lives_ok { $c->update } 'Update entry';

# check updated entry
{
  my $e = MyCaches::Model::Find->new(
    db => $t->app->sqlite->db,
    load => { id => $c->id }
  );
  isa_ok($e, 'MyCaches::Model::Find');
  is($e->name, 'Pěl ďábelské ódy', 'Check updated entry');
}

# delete entry
lives_ok { $c->delete } 'Delete entry';
throws_ok {
  $d = MyCaches::Model::Find->new(
    db => $t->app->sqlite->db,
    load => { cacheid => 'GC9ABCD' }
  )
} qr/Find \w+ not found/, 'Deleted entry retrieval';

# finish
done_testing();
