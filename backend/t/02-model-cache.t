#!/usr/bin/perl

# Test MyCaches::Model::Cache

use utf8;
use Mojo::Base -strict;
use Test2::V0;
use Test2::MojoX;
use MyCaches::Model::Cache;
use MyCaches::Model::Const;

my $t = Test2::MojoX->new('MyCaches', { dbfile => ':temp:' });
my $db = $t->app->sqlite;

#--- instance creation ---------------------------------------------------------

{ # instance creation, default
  my $c = MyCaches::Model::Cache->new(sqlite => $db);
  is($c, object {
    prop blessed => 'MyCaches::Model::Cache';
    call sqlite => check_isa 'Mojo::SQLite';
    call id => U();
    call cacheid => U();
    call name => U();
    call difficulty => 1;
    call terrain => 1;
    call ctype => 2;
    call gallery => 0;
    call status => ST_UNDEF;
    call now => object { prop blessed => 'Time::Moment' };
    call now => Time::Moment->now->at_midnight;
    call tz => $c->now->strftime('%:z');
  }, 'Default instance check');
}

{ # non-default instance from direct arguments
  my $c = MyCaches::Model::Cache->new(
    sqlite => $db,
    id => 123,
    cacheid => 'GC9ABCD',
    name => 'Žluťoučký kůň 🐴',
    difficulty => 5,
    terrain => 4.5,
    ctype => 4,
    gallery => 1,
    status => ST_DISABLED,
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Cache';
    call id => 123;
    call cacheid => 'GC9ABCD';
    call name => 'Žluťoučký kůň 🐴';
    call difficulty => 5;
    call terrain => 4.5;
    call ctype => 4;
    call gallery => 1;
    call status => ST_DISABLED;
    call now => object { prop blessed => 'Time::Moment' };
    call now => Time::Moment->now->at_midnight;
    call tz => $c->now->strftime('%:z');
  }, 'Non-default instance check (direct)');
}

{ # empty strings converted to undefs in attributes
  my $c = MyCaches::Model::Cache->new(
    sqlite => $db,
    cacheid => '',
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Cache';
    call cacheid => U();
  }, 'Empty strings to undefs');
}

{ # non-default instance from database entry
  my $c = MyCaches::Model::Cache->new(
    sqlite => $db,
    entry => {
      cacheid => 'GC9ABCD',
      name => 'Žluťoučký kůň 🐴',
      difficulty => 10,
      terrain => 9,
      ctype => 4,
      gallery => 1,
      status => ST_ACTIVE,
    }
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Cache';
    call cacheid => 'GC9ABCD';
    call name => 'Žluťoučký kůň 🐴';
    call difficulty => 5;
    call terrain => 4.5;
    call ctype => 4;
    call gallery => 1;
    call status => ST_ACTIVE;
    call now => object { prop blessed => 'Time::Moment' };
    call now => Time::Moment->now->at_midnight;
    call tz => $c->now->strftime('%:z');
  }, 'Non-default instance check (db entry)');

#--- data export ---------------------------------------------------------------

  { # export attributes as hash
    my $h = $c->to_hash;
    is($h, hash {
      field cacheid => 'GC9ABCD';
      field name => 'Žluťoučký kůň 🐴';
      field difficulty => 5;
      field terrain => 4.5;
      field ctype => 4;
      field gallery => 1;
      field status => ST_ACTIVE;
      field tz => $c->now->strftime('%:z');
      etc();
    }, 'Data export');
  }

  { # export attributes as hash for db
    my $h = $c->to_hash(db => 1);
    is($h, hash {
      field difficulty => 10;
      field terrain => 9;
      etc();
    }, 'Data export (for db)');
  }

#--- getting last id -----------------------------------------------------------

  is($c->get_last_id('hides'), 0, 'Last row id on empty hides table');
  is($c->get_last_id('finds'), 0, 'Last row id on empty finds table');


#--- date arithmetic -----------------------------------------------------------

  my $tm1 = Time::Moment->from_string('2020-01-01T00Z');
  my $tm2 = Time::Moment->from_string('2020-01-01T00Z');

  is(
    $c->calc_years_days($tm1, $tm2),
    hash { field years => 0; field days => 0; field rdays => 0; end() },
    'Date difference (1)'
  );

  $tm2 = $tm2->plus_days(1);
  is(
    $c->calc_years_days($tm1, $tm2),
    hash { field years => 0; field days => 1; field rdays => 1; end() },
    'Date difference (2)'
  );

  $tm2 = $tm2->plus_years(1);
  is(
    $c->calc_years_days($tm1, $tm2),
    hash { field years => 1; field days => 367; field rdays => 1; end() },
    'Date difference (3)'
  );
}

# finish
done_testing();
