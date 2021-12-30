#!/usr/bin/perl

# Test MyCaches::Model::Log and MyCaches::Model::LogList

use utf8;
use Mojo::Base -strict;
use Test::Mojo;
use Test::Most;
use Path::Tiny qw(tempfile);
use Time::Moment;
use MyCaches::Model::Log;
use MyCaches::Model::Hide;
use MyCaches::Model::Const;
use MyCaches::Model::Loglist;

my $t = Test::Mojo->new('MyCaches', { dbfile => tempfile });
my $today = Time::Moment->now->strftime('%F');

my %entry = (
  db => $t->app->sqlite->db,
  seq => 100,
  date => '2011-12-14',
  cacheid => 'GC9ABCD',
  player => 'PlayerOne',
  logtype => LT_FOUNDIT,
  logid => '3b0a3b3a-6961-11ec-a145-53667f57d000',
);

#--- instance creation ---------------------------------------------------------

{
  my $log = MyCaches::Model::Log->new;
  isa_ok($log, 'MyCaches::Model::Log');
}

#--- basic attribute tests -----------------------------------------------------

{ # date, basic format
  my $log = MyCaches::Model::Log->new(date => '2011-12-14');
  isa_ok($log->date, 'Time::Moment');
  is($log->date->strftime('%F'), '2011-12-14');
}

{ # date, alternate format
  my $log = MyCaches::Model::Log->new(date => '14/12/2011');
  isa_ok($log->date, 'Time::Moment');
  is($log->date->strftime('%F'), '2011-12-14');
}

#--- instance with data --------------------------------------------------------

{
  my $log = MyCaches::Model::Log->new(%entry);
  my $h = $log->to_hash;
  cmp_deeply($h, subhashof(\%entry));
}

#--- create db entry and failing reference check -------------------------------

{
  my $log = MyCaches::Model::Log->new(%entry);
  throws_ok {
    $log->add_log
  } qr/FOREIGN KEY constraint failed/, 'Create entry failing ref check';
}

#--- prepare testing entry in hides --------------------------------------------

my $hide = MyCaches::Model::Hide->new(
  db => $t->app->sqlite->db,
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  published => '2018-12-18',
  found => $today,
  finds => 321,
  status => 1,
);
isa_ok($hide, 'MyCaches::Model::Hide');
lives_ok { $hide->create } 'Prepare a hide';

#--- create db entry and satisfying reference check ----------------------------

{
  # 'seq' field explicitly specified
  my $log = MyCaches::Model::Log->new(%entry);
  lives_ok {
    $log->add_log
  } 'Create entry (explicit seq)';
  is($log->get_next_seq, 101, 'Next sequence id (explicit)');

  # implicit 'seq' field
  $log->seq(undef);
  lives_ok {
    $log->add_log
  } 'Create entry (implicit seq)';
  is($log->get_next_seq, 102, 'Next sequence id (implicit)');
}

#--- loading entries -----------------------------------------------------------

{ # loading all entries
  my $list;
  lives_ok {
    $list = MyCaches::Model::Loglist->load($t->app->sqlite->db)
  } 'Load entries (1)';
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 2, 'List size (1)');

  # compare content
  my %entry_cmp = (%entry, logs_i => 1);
  cmp_deeply(\%entry_cmp, superhashof($list->[0]->to_hash), 'Check saved entry (1)');
  %entry_cmp = (%entry, logs_i => 2, seq => 101);
  cmp_deeply(\%entry_cmp, superhashof($list->[1]->to_hash), 'Check saved entry (2)');
}

{ # load specified entries
  my $list;
  lives_ok {
    $list = MyCaches::Model::Loglist->load($t->app->sqlite->db, seq => 100 );
  } 'Load entries (2)';
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 1, 'List size (2)');
}

{ # load specified entries
  my $list;
  lives_ok {
    $list = MyCaches::Model::Loglist->load(
      $t->app->sqlite->db, date => $entry{date}
    );
  } 'Load entries (3)';
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 2, 'List size (3)');
}

#--- updating entries ----------------------------------------------------------

{
  my $list;
  lives_ok {
    $list = MyCaches::Model::Loglist->load($t->app->sqlite->db, logs_i => 1 );
  } 'Load entries (3)';
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 1, 'List size (4)');

  # update entry
  $list->[0]->{player} = 'Monifique'; # bypass 'ro' on the attribute
  lives_ok { $list->[0]->update_log } 'Update entry';

  lives_ok {
    $list = MyCaches::Model::Loglist->load($t->app->sqlite->db, logs_i => 1 );
  } 'Load entries (4)';
  is($list->size, 1, 'List size (5)');
  is($list->[0]->player, 'Monifique', 'Updated value check');

  # updating entry in a way that will violate foreign key constraint
  $list->[0]->{cacheid} = 'GC1NEXI'; # bypass 'ro' on the attribute
  throws_ok { $list->[0]->update_log } qr/FOREIGN KEY constraint failed/;
}

#--- deleting entries ----------------------------------------------------------

{
  my $list;
  lives_ok {
    $list = MyCaches::Model::Loglist->load($t->app->sqlite->db);
  } 'Load entries (5)';
  isa_ok($list, 'MyCaches::Model::Loglist');
  is($list->size, 2, 'List size (6)');

  lives_ok { $list->[0]->delete_log } 'Delete entry';
  lives_ok { $list->[1]->delete_log } 'Delete entry';

  $list = MyCaches::Model::Loglist->load($t->app->sqlite->db);
  is($list->size, 0, 'List is empty');
}

#--- finish --------------------------------------------------------------------

done_testing();
