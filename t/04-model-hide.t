#!/usr/bin/perl

# Test MyCaches::Model::Hide

use utf8;
use Mojo::Base -strict;
use Test::Mojo;
use Test::Most;
use Path::Tiny qw(tempfile);
use MyCaches::Model::Hide;

my $t = Test::Mojo->new('MyCaches', { dbfile => tempfile });
my $today = Time::Moment->now->strftime('%F');

#--- instance creation and data ops --------------------------------------------

# instance creation, default
my $c = MyCaches::Model::Hide->new;
isa_ok($c, 'MyCaches::Model::Hide');
cmp_deeply($c, methods(
  published => undef,
  finds => 0,
  found => undef,
  status => 0,
  age => undef,
));

# instance creation, non-default
$c = MyCaches::Model::Hide->new(
  published => '2018-12-18',
  finds => 123,
  found => $today,
  status => 1,
);
isa_ok($c, 'MyCaches::Model::Hide');
cmp_deeply($c, methods(
  published => Time::Moment->from_string('2018-12-18T00:00' . $c->tz),
  finds => 123,
  found => Time::Moment->from_string("${today}T00:00" . $c->tz),,
  status => 1,
  age => { years => 0, days => 0, rdays => 0 },
));

# instance creation, non-default, from db entry
$c = MyCaches::Model::Hide->new(
  entry => {
    hides_i => 123,
    cacheid => 'GC9ABCD',
    name => 'Žluťoučký kůň 🐴',
    difficulty => 10,
    terrain => 9,
    ctype => 4,
    gallery => 1,
    archived => 1,
    published => '2018-12-18',
    found => $today,
    finds => 321,
    status => 1,
  }
);
isa_ok($c, 'MyCaches::Model::Hide');
cmp_deeply($c, methods(
  id => 123,
  published => Time::Moment->from_string('2018-12-18T00:00' . $c->tz),
  finds => 321,
  found => Time::Moment->from_string("${today}T00:00" . $c->tz),
  status => 1,
  age => { years => 0, days => 0, rdays => 0 },
));

# export of attributes
{
  my $h = $c->to_hash;
  cmp_deeply($h, superhashof({
    hides_i => 123,
    published => '2018-12-18',
    finds => 321,
    found => $today,
    status => 1,
    age => { years => 0, days => 0, rdays => 0 },
  }));
}

# export of attributes for db
{
  my $h = $c->to_hash(db => 1);
  ok(!exists $h->{age}, q{Attribute 'age' export suppression});
}

# instance creation, ingestion of alternate date format
$c = MyCaches::Model::Hide->new(
  published => '18/12/2018',
  found => '17/12/2021',
);
isa_ok($c, 'MyCaches::Model::Hide');
is($c->published->strftime('%F'), '2018-12-18' );
is($c->found->strftime('%F'), '2021-12-17' );

#--- database operations -------------------------------------------------------

# create an entry in db
$c = MyCaches::Model::Hide->new(
  db => $t->app->sqlite->db,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  archived => 0,
  status => 1,
  published => '2018-12-08',
  found => '2019-01-19',
  finds => 123,
);
isa_ok($c, 'MyCaches::Model::Hide');
lives_ok { $c->create } 'Create entry';
is($c->id, 1, 'New entry row id');

# load the entry by row id
# load the entry by row id
my $d = MyCaches::Model::Hide->new(
  db => $t->app->sqlite->db,
  load => { id => $c->id }
);
isa_ok($d, 'MyCaches::Model::Hide');
cmp_deeply($d, methods(
  id => 1,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  archived => 0,
  status => 1,
  finds => 123,
), 'Load entry by id (1)');
is($d->published->strftime('%F'), '2018-12-08', 'Load entry by id (2)');
is($d->found->strftime('%F'), '2019-01-19', 'Load entry by id (3)');

# load the entry by cache id
$d = MyCaches::Model::Hide->new(
  db => $t->app->sqlite->db,
  load => { cacheid => 'GC9ABCD' }
);
isa_ok($d, 'MyCaches::Model::Hide');
cmp_deeply($d, methods(
  id => 1,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  archived => 0,
  status => 1,
  finds => 123,
), 'Load entry by id (1)');
is($d->published->strftime('%F'), '2018-12-08', 'Load entry by id (2)');
is($d->found->strftime('%F'), '2019-01-19', 'Load entry by id (3)');

# check finding the next row id
$d->get_new_id;
is($d->id, 2, 'Getting new rowid');

# update an entry in db
$c->{name} = 'Pěl ďábelské ódy'; # bypassing r/o accessor
lives_ok { $c->update } 'Update entry';

# check updated entry
{
  my $e = MyCaches::Model::Hide->new(
    db => $t->app->sqlite->db,
    load => { id => $c->id }
  );
  isa_ok($e, 'MyCaches::Model::Hide');
  is($e->name, 'Pěl ďábelské ódy', 'Check updated entry');
}

# delete entry frm db
lives_ok { $c->delete } 'Delete entry';
throws_ok {
  $d = MyCaches::Model::Hide->new(
    db => $t->app->sqlite->db,
    load => { cacheid => 'GC9ABCD' }
  )
} qr/Hide \w+ not found/, 'Deleted entry retrieval';

# finish
done_testing();
