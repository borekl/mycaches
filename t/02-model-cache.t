#!/usr/bin/perl

# Test MyCaches::Model::Cache

use utf8;
use Mojo::Base -strict;
use Test::Mojo;
use Test::Most;
use Path::Tiny qw(tempfile);
use MyCaches::Model::Cache;

my $t = Test::Mojo->new('MyCaches', { dbfile => tempfile });

# instance creation, default
my $c = MyCaches::Model::Cache->new(db => $t->app->sqlite->db);
isa_ok($c, 'MyCaches::Model::Cache');
cmp_deeply($c, methods(
  id => undef,
  cacheid => undef,
  name => undef,
  difficulty => 1,
  terrain => 1,
  ctype => 2,
  gallery => 0,
  status => 0,
  now => isa('Time::Moment'),
  now => Time::Moment->now->at_midnight,
  tz => $c->now->strftime('%:z')
));

# non-default instance from direct arguments
$c = MyCaches::Model::Cache->new(
  db => $t->app->sqlite->db,
  id => 123,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  status => 1,
);
isa_ok($c, 'MyCaches::Model::Cache');
cmp_deeply($c, methods(
  id => 123,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  status => 1,
  now => isa('Time::Moment'),
  now => Time::Moment->now->at_midnight,
  tz => $c->now->strftime('%:z')
));

# non-default instance from database entry
$c = MyCaches::Model::Cache->new(
  db => $t->app->sqlite->db,
  entry => {
    cacheid => 'GC9ABCD',
    name => 'Žluťoučký kůň 🐴',
    difficulty => 10,
    terrain => 9,
    ctype => 4,
    gallery => 1,
    status => 1,
  }
);
isa_ok($c, 'MyCaches::Model::Cache');
cmp_deeply($c, methods(
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  status => 1,
));

# export attributes as hash
{
  my $h = $c->to_hash;
  cmp_deeply($h, {
    cacheid => 'GC9ABCD',
    name => 'Žluťoučký kůň 🐴',
    difficulty => 5,
    terrain => 4.5,
    ctype => 4,
    gallery => 1,
    status => 1,
    tz => $c->now->strftime('%:z'),
  });
}

# export attributes as hash for db
{
  my $h = $c->to_hash(db => 1);
  cmp_deeply($h, superhashof ({
    difficulty => 10,
    terrain => 9,
  }));
}

# empty strings converted to undefs in attributes
$c = MyCaches::Model::Cache->new(
  db => $t->app->sqlite->db,
  cacheid => '',
);
isa_ok($c, 'MyCaches::Model::Cache');
is($c->cacheid, undef, q{Attribute 'cacheid' empty string});

# last row id
is($c->get_last_id('hides'), 0, 'Last row id on empty hides table');
is($c->get_last_id('finds'), 0, 'Last row id on empty finds table');

# difference between two dates
{
  my $tm1 = Time::Moment->from_string('2020-01-01T00Z');
  my $tm2 = Time::Moment->from_string('2020-01-01T00Z');

  cmp_deeply(
    $c->calc_years_days($tm1, $tm2),
    { years => 0, days => 0, rdays => 0 }
  );

  $tm2 = $tm2->plus_days(1);
  cmp_deeply(
    $c->calc_years_days($tm1, $tm2),
    { years => 0, days => 1, rdays => 1 }
  );

  $tm2 = $tm2->plus_years(1);
  cmp_deeply(
    $c->calc_years_days($tm1, $tm2),
    { years => 1, days => 367, rdays => 1 }
  );
}

# finish
done_testing();
