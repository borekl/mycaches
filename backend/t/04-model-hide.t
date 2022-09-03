#!/usr/bin/perl

# Test MyCaches::Model::Hide

use utf8;
use Mojo::Base -strict;
use Test2::V0;
use Test2::MojoX;
use MyCaches::Model::Hide;

my $t = Test2::MojoX->new('MyCaches', { dbfile => ':temp:' });

#--- instance creation ---------------------------------------------------------

{ # instance creation, default
  my $c = $t->app->myhide;
  is($c, object {
    prop blessed => 'MyCaches::Model::Hide';
    call sqlite => check_isa 'Mojo::SQLite';
    call published => U();
    call finds => 0;
    call found => U();
    call status => 0;
    call age => U();
  }, 'Default instance check');

  # backend table check
  is($c->_db_table, 'hides', 'Backend table check');
}

{ # instance creation, non-default
  my $c = $t->app->myhide(
    published => '2018-12-18',
    finds => 123,
    found => Time::Moment->now->at_midnight,
    status => 1,
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Hide';
    call published => object { prop blessed => 'Time::Moment' };
    call published => Time::Moment->from_string('2018-12-18T00:00' . $c->tz);
    call finds => 123;
    call found => object { prop blessed => 'Time::Moment' };
    call found => Time::Moment->now->at_midnight;
    call status => 1;
    call age => hash {
      field years => 0; field days => 0; field rdays => 0; end()
    };
  }, 'Non-default instance check')
}

{ # instance creation, non-default, from db entry
  my $c = $t->app->myhide(
    entry => {
      hides_i => 123,
      cacheid => 'GC9ABCD',
      name => 'Žluťoučký kůň 🐴',
      difficulty => 10,
      terrain => 9,
      ctype => 4,
      gallery => 1,
      published => '2018-12-18',
      found => Time::Moment->now->strftime('%F'),
      finds => 321,
      status => 1,
    }
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Hide';
    call id => 123;
    call published => object { prop blessed => 'Time::Moment' };
    call published => Time::Moment->from_string('2018-12-18T00:00' . $c->tz);
    call finds => 321;
    call found => object { prop blessed => 'Time::Moment' };
    call found => Time::Moment->now->at_midnight;
    call status => 1;
    call age => hash {
      field years => 0; field days => 0; field rdays => 0; end()
    };
  }, 'Non-default instance check (from db)');

  { # data export
    my $h = $c->to_hash;
    is($h, hash {
      field hides_i => 123;
      field published => '2018-12-18';
      field finds => 321;
      field found => Time::Moment->now->at_midnight->strftime('%F');
      field status => 1;
      field age => { years => 0, days => 0, rdays => 0 };
      etc();
    }, 'Data export to hash');
  }

  { # data export for db
    my $h = $c->to_hash(db => 1);
    is($h, hash { field age => DNE(); etc() }, 'Data export to hash (db)');
  }
}

{ # instance creation, ingestion of alternate date format
  my $c = $t->app->myhide(
    published => '18/12/2018',
    found => '17/12/2021',
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Hide';
    call published => object { prop blessed => 'Time::Moment' };
    call published => Time::Moment->from_string('2018-12-18T00:00' . $c->tz);
    call found => object { prop blessed => 'Time::Moment' };
    call found => Time::Moment->from_string('2021-12-17T00:00' . $c->tz);
  }, 'Ingestion of alt date format');
}

#--- database operations -------------------------------------------------------

{ # create an entry in db
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
    finds => 123,
  );
  isa_ok($c, 'MyCaches::Model::Hide');
  ok(lives { $c->create }, 'Create entry') or diag($@);
  is($c->id, 1, 'New entry rowid');

  { # load the entry by row id
    my $d = $t->app->myhide(
      load => { id => $c->id }
    );
    is($d, object {
      prop blessed => 'MyCaches::Model::Hide';
      call id => 1;
      call cacheid => 'GC9ABCD';
      call name => 'Žluťoučký kůň 🐴';
      call difficulty => 5;
      call terrain => 4.5;
      call ctype => 4;
      call gallery => 1;
      call status => 1;
      call finds => 0;
    }, 'Load entry by id (1)');
  }

  { # load the entry by cache id
    my $d = $t->app->myhide(
      load => { cacheid => 'GC9ABCD' }
    );
    is($d, object {
      prop blessed => 'MyCaches::Model::Hide';
      call id => 1;
      call cacheid => 'GC9ABCD';
      call name => 'Žluťoučký kůň 🐴';
      call difficulty => 5;
      call terrain => 4.5;
      call ctype => 4;
      call gallery => 1;
      call status => 1;
      call finds => 0;
    }, 'Load entry by id (1)');

    # check finding the next row id
    $d->get_new_id;
    is($d->id, 2, 'Getting new rowid');
  }

  # update an entry in db
  $c->{name} = 'Pěl ďábelské ódy'; # bypassing r/o accessor
  ok(lives { $c->update }, 'Update entry') or diag($@);

  { # check the updated entry
    my $e = $t->app->myhide(
      load => { id => $c->id }
    );
    is($e, object {
      prop blessed => 'MyCaches::Model::Hide';
      call name => string 'Pěl ďábelské ódy';
    }, 'Check updated entry');
  }

  # delete entry from db
  ok(lives { $c->delete }, 'Delete entry') or diag($@);
  like(dies {
    $t->app->myhide(
      load => { cacheid => 'GC9ABCD' }
    )
  }, qr/Hide \w+ not found/, 'Deleted entry retrieval');

  # delete this entry again, this should fail
  like(dies {
    $c->delete
  }, qr/Hide \d+ not found/, 'Deleting non-existent entry');

  # updating non-existent entry should fail too
  like(dies {
    $c->update
  }, qr/Hide \d+ not found/, 'Updating non-existent entry');
}

#--- finish --------------------------------------------------------------------

done_testing;
