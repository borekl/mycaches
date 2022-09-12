#!/usr/bin/perl

use experimental 'postderef';
use utf8;
use Mojo::Base -strict;
use Test2::V0;
use Test2::MojoX;

# initialize testing environment
my $t = Test2::MojoX->new('MyCaches', { dbfile => ':temp:' });
my $uuid = '3a7346e9-6c20-4ebc-815b-d4a36b90a09e';

# create a hide
my $c = $t->app->myhide(
  cacheid => 'GC9ABCD',
  name => 'Žluťoučký kůň 🐴',
  difficulty => 5,
  terrain => 4.5,
  ctype => 4,
  gallery => 1,
  status => 1,
  published => '2018-12-08',
  found => '2019-01-19',
);
isa_ok($c, 'MyCaches::Model::Hide');
ok(lives { $c->create }, 'Create entry') or diag($@);
is($c->id, 1, 'New entry rowid');

{ #=== session 1 ===============================================================

  # instance creation
  my $ll = $t->app->loglist(cacheid => 'GC9ABCd');
  isa_ok($ll, 'MyCaches::Model::Loglist');

  # cacheid capitalization
  is($ll->cacheid, 'GC9ABCD', 'Cacheid capitalization');

  # loading empty list
  is($ll->logs, hash { end; }, 'Empty loglist check');

  # check last rowid with an empty list
  is($ll->get_last_id, 0, 'Last id with empty loglist');

  # check next seq with an empty list
  is($ll->get_next_seq('2022-01-01'), 0, 'Next seq number with empty loglist');

  { #  entry #1 creation // check assignment of correct rowid and sequence number
    my $e;
    ok(lives {
      $e = $ll->add(
        date => '2022-01-01',
        cacheid => 'GC9ABCD',
        player => 'testplayer1',
        logtype => 1,
      );
    }, 'Create log entry') or diag($@);
    is($e->{logs_i}, 1, 'New entry (#1) rowid');
    is($e->{seq}, 0, 'New entry (#1) seq');
  }

  { # entry #2 creation // check properly incrementing rowid and sequence
    #number
    my $e;
    ok(lives {
      $e = $ll->add(
        date => '2022-01-01',
        cacheid => 'GC9ABCD',
        player => 'testplayer2',
        logtype => 1,
      );
    }, 'Create log entry') or diag($@);
    is($e->{logs_i}, 2, 'New entry (#2) rowid');
    is($e->{seq}, 1, 'New entry (#2) seq');
  }

  { # entry #3 creation // check properly incrementing rowid and sequence
    #number
    my $e;
    ok(lives {
      $e = $ll->add(
        date => '2022-01-01',
        cacheid => 'GC9ABCD',
        player => 'testplayer2',
        logtype => 1,
      );
    }, 'Create log entry (#3)') or diag($@);
    is($e->{logs_i}, 3, 'New entry (#3) rowid');
    is($e->{seq}, 2, 'New entry (#3) seq');
  }

  { # try to create a new entry with incorrect cacheid, this should throw
    # exception
    like(
      dies {
        $ll->add(
          date => '2022-01-01',
          cacheid => 'GC9EFGH',
          player => 'testplayer2',
          logtype => 1,
        );
      },
      qr/Invalid cacheid/,
      'Adding entry with invalid cacheid'
    ) or diag($@);
  }

}

{ #=== session 2 ===============================================================

  my $ll = $t->app->loglist(cacheid => 'GC9ABCD');

  # check number of entries in the database
  is(scalar(keys $ll->logs->%*), 3, 'Load entries from db, check count (1)');

  # verify content of an entry
  is($ll->logs->{1}, hash {
    field date => '2022-01-01';
    field cacheid => 'GC9ABCD';
    field player => 'testplayer1';
    field logtype => 1;
    field logs_i => 1;
    field logid => U();
    field seq => 0;
    end;
  }, 'Entry content check');

  # update entry #1
  ok(lives { $ll->update(1, logid => $uuid )}, 'Entry update check') or diag($@);
  is($ll->logs->{1}{logid}, $uuid, 'Entry update check (in-memory');

  # delete entry #2
  ok(lives { $ll->delete(2) }, 'Entry deletion check');
  ok(!exists $ll->logs->{2}, 'Entry deletion check (in-memory)');
}

{ #=== session 3 ===============================================================

  my $ll = $t->app->loglist(cacheid => 'GC9ABCD');

  # check number of entries in the database
  is(scalar(keys $ll->logs->%*), 2, 'Load entries from db, check count (2)');

  # verify content of an entry #1
  is($ll->logs->{1}, hash {
    field date => '2022-01-01';
    field cacheid => 'GC9ABCD';
    field player => 'testplayer1';
    field logtype => 1;
    field logs_i => 1;
    field logid => $uuid;
    field seq => 0;
    end;
  }, 'Entry content check');

  # verify content of an entry #3
  is($ll->logs->{3}, hash {
    field date => '2022-01-01';
    field cacheid => 'GC9ABCD';
    field player => 'testplayer2';
    field logtype => 1;
    field logs_i => 3;
    field logid => U();
    field seq => 2;
    end;
  }, 'Entry content check');

  # swap sequence of the two extant entries
  ok(lives { $ll->swap(1, 3) }, 'Swap entries') or diag($@);
}

{ #=== session 4 ===============================================================

  my $ll = $t->app->loglist(cacheid => 'GC9ABCD');

  # verify content of an entry #1
  is($ll->logs->{1}, hash {
    field seq => 2;
    etc;
  }, 'Entry content check (after swap)');

  # verify content of an entry #3
  is($ll->logs->{3}, hash {
    field seq => 0;
    etc;
  }, 'Entry content check (after swap)');

}

# finish
done_testing;
