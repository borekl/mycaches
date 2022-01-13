#!/usr/bin/perl

# Test MyCaches::Model::Log and MyCaches::Model::LogList

use utf8;
use Mojo::Base -strict;
use Test2::V0;
use Test2::MojoX;
use Time::Moment;
use MyCaches::Model::Log;
use MyCaches::Model::Hide;
use MyCaches::Model::Const;
use MyCaches::Model::Loglist;

my $t = Test2::MojoX->new('MyCaches', { dbfile => ':temp:' });
my $db = $t->app->sqlite->db;
my $today = Time::Moment->now->strftime('%F');

my %entry = (
  seq => 100,
  date => '2011-12-14',
  cacheid => 'GC9ABCD',
  player => 'PlayerOne',
  logtype => LT_FOUNDIT,
  logid => '3b0a3b3a-6961-11ec-a145-53667f57d000',
);

#--- instance creation ---------------------------------------------------------

{ # date, basic format
  my $log = MyCaches::Model::Log->new(date => '2011-12-14');
  is($log, object {
    prop blessed => 'MyCaches::Model::Log';
    call date => object { prop blessed => 'Time::Moment' };
    call date => Time::Moment->from_string('2011-12-14T00:00' . $log->tz);
  }, 'Instance creation');
}

{ # date, alternate format
  my $log = MyCaches::Model::Log->new(date => '14/12/2011');
  is($log, object {
    prop blessed => 'MyCaches::Model::Log';
    call date => object { prop blessed => 'Time::Moment' };
    call date => Time::Moment->from_string('2011-12-14T00:00' . $log->tz);
  }, 'Instance creation (alt date format)');
}

{ # instance with data
  my $log = MyCaches::Model::Log->new(%entry, db => $db);
  my $h = $log->to_hash;
  is($h, \%entry, 'Instance creation (with data)');
}

#--- create db entry and failing reference check -------------------------------

{
  my $log = MyCaches::Model::Log->new(%entry, db => $db);
  like(dies {
    $log->add_log
  }, qr/FOREIGN KEY constraint failed/, 'Create entry failing ref check');
}

#--- prepare testing entry in hides --------------------------------------------

{
  my $hide = $t->app->hide(
    cacheid => 'GC9ABCD',
    name => 'Žluťoučký kůň 🐴',
    difficulty => 5,
    terrain => 4.5,
    ctype => 4,
    gallery => 1,
    published => '2018-12-18',
    found => Time::Moment->now->at_midnight,
    finds => 321,
    status => 1,
  );
  isa_ok($hide, 'MyCaches::Model::Hide');
  ok(lives { $hide->create }, 'Prepare a hide') or diag($@);
}

#--- create db entry satisfying reference check --------------------------------

{ # 'seq' field explicitly specified
  my $log = MyCaches::Model::Log->new(%entry, db => $db);
  ok(lives {
    $log->add_log
  }, 'Create entry (explicit seq)') or diag($@);
  is($log->get_next_seq, 101, 'Next sequence id (explicit)');

  # implicit 'seq' field
  $log->seq(undef);
  ok(lives {
    $log->add_log
  }, 'Create entry (implicit seq)') or diag($@);
  is($log->get_next_seq, 102, 'Next sequence id (implicit)');
}

#--- loading entries -----------------------------------------------------------

{ # loading all entries
  my $list;
  ok(lives {
    $list = MyCaches::Model::Loglist->load($db)
  }, 'Load entries (1)') or diag($@);
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 2, 'List size (1)');

  # compare content
  is($list->[0]->to_hash, { %entry, logs_i => 1 }, 'Check saved entry (1)');
  is($list->[1]->to_hash, { %entry, logs_i => 2, seq => 101}, 'Check saved entry (2)');
}

{ # load specified entries
  my $list;
  ok(lives {
    $list = MyCaches::Model::Loglist->load($db, seq => 100 );
  }, 'Load entries (2)') or diag($@);
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 1, 'List size (2)');
}

{ # load specified entries
  my $list;
  ok(lives {
    $list = MyCaches::Model::Loglist->load($db, date => $entry{date});
  }, 'Load entries (3)') or diag($@);
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 2, 'List size (3)');
}

#--- updating entries ----------------------------------------------------------

{ # load an entry so we can update it
  my $list;
  ok(lives {
    $list = MyCaches::Model::Loglist->load($db, logs_i => 1 );
  }, 'Load entries (3)') or diag($@);
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 1, 'List size (4)');

  # update entry
  $list->[0]->{player} = 'Monifique'; # bypass 'ro' on the attribute
  ok(lives { $list->[0]->update_log }, 'Update entry') or diag($@);

  ok(lives {
    $list = MyCaches::Model::Loglist->load($db, logs_i => 1 );
  }, 'Load entries (4)') or diag($@);
  is($list->size, 1, 'List size (5)');
  is($list->[0]->player, 'Monifique', 'Updated value check');

  # updating entry in a way that will violate foreign key constraint
  $list->[0]->{cacheid} = 'GC1NEXI'; # bypass 'ro' on the attribute
  ok(
    dies { $list->[0]->update_log },
    qr/FOREIGN KEY constraint failed/,
    'Update violating constraint'
  );
}

#--- deleting entries ----------------------------------------------------------

{ # load an entry so we can update it
  my $list;
  ok(lives {
    $list = MyCaches::Model::Loglist->load($db);
  }, 'Load entries (5)') or diag($@);
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 2, 'List size (6)');

  ok(lives { $list->[0]->delete_log }, 'Delete entry') or diag($@);
  ok(lives { $list->[1]->delete_log }, 'Delete entry') or diag($@);

  $list = MyCaches::Model::Loglist->load($db);
  is($list->size, 0, 'List is empty');
}

#--- finish --------------------------------------------------------------------

done_testing();
