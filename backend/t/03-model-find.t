#!/usr/bin/perl

# Test MyCaches::Model::Find

use utf8;
use Mojo::Base -strict;
use Test2::V0;
use Test2::MojoX;

my $t = Test2::MojoX->new('MyCaches', { dbfile => ':temp:' });

#--- instance creation ---------------------------------------------------------

{ # instance creation, default
  my $c = $t->app->myfind;
  is($c, object {
    prop blessed => 'MyCaches::Model::Find';
    call sqlite => check_isa 'Mojo::SQLite';
    call prev => U();
    call found => U();
    call next => U();
    call favorite => 0;
    call xtf => 0;
    call logid => U();
    call age => U();
    call held => U();
  }, 'Default instance check');
}

done_testing;
exit;

{ # instance creation, non-default
  my $c = $t->app->myfind(
    prev => '2019-01-19',
    found => '2019-01-19',
    next => '2019-01-19',
    favorite => 1,
    xtf => 1,
    logid => 'abcdef-012',
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Find';
    call prev => Time::Moment->from_string('2019-01-19T00:00' . $c->tz);
    call found => Time::Moment->from_string('2019-01-19T00:00' . $c->tz);
    call next => Time::Moment->from_string('2019-01-19T00:00' . $c->tz);
    call favorite => 1;
    call xtf => 1;
    call logid => 'abcdef-012';
    call age => hash {
      field years => 0; field days => 0; field rdays => 0; end()
    };
    call held => hash {
      field years => 0; field days => 0; field rdays => 0; end()
    };
  }, 'Non-default instance check');
}

{ # instance creation, non-default, from db entry
  my $c = $t->app->myfind(
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
  is($c, object {
    prop blessed => 'MyCaches::Model::Find';
    call prev => Time::Moment->from_string('2019-01-19T00:00' . $c->tz);
    call found => Time::Moment->from_string('2019-01-19T00:00' . $c->tz);
    call next => Time::Moment->from_string('2019-01-19T00:00' . $c->tz);
    call favorite => 1;
    call xtf => 1;
    call logid => 'abcdef-012';
    call age => hash {
      field years => 0; field days => 0; field rdays => 0; end()
    };
    call held => hash {
      field years => 0; field days => 0; field rdays => 0; end()
    };
  }, 'Non-default instance check (db)');


  { # export of attributes
    my $h = $c->to_hash;
    is($h, hash {
      field finds_i => $c->id;
      field prev => $c->prev->strftime('%F');
      field found => $c->found->strftime('%F');
      field next => $c->next->strftime('%F');
      field favorite => $c->xtf;
      field xtf => $c->xtf;
      field logid => $c->logid;
      field age => $c->age;
      field held => $c->held;
      etc()
    }, 'Data export');
  }

  { # export of attributes for db
    my $h = $c->to_hash(db => 1);
    is($h, hash {
      field age => DNE();
      field held => DNE();
      etc()
    }, 'Data export for db');
  }
}

{ # instance creation, ingestion of alternate date format
  my $c = $t->app->myfind(
    prev => '1/1/2019',
    found => '19/10/2019',
    next => '01/01/2020',
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Find';
    call prev => Time::Moment->from_string('2019-01-01T00:00' . $c->tz);
    call found => Time::Moment->from_string('2019-10-19T00:00' . $c->tz);
    call next => Time::Moment->from_string('2020-01-01T00:00' . $c->tz);
  }, 'Non-default instance, alt date format');
}

#--- date arithmetic -----------------------------------------------------------

{ # testing date arithmetic (1)
  my $c = $t->app->myfind(
    prev => '2019-01-19',
    found => '2019-01-20',
    next => '2019-01-21',
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Find';
    call age => hash {
      field years => 0; field days => 1; field rdays => 1; end()
    };
    call held => hash {
      field years => 0; field days => 1; field rdays => 1; end()
    };
  }, 'Date arithmetic (1)');
}

{ # testing date arithmetic (2)
  my $c = $t->app->myfind(
    prev => '2019-12-31',
    found => '2020-12-31',
    next => '2022-01-01',
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Find';
    call age => hash {
      field years => 1; field days => 366; field rdays => 0; end()
    };
    call held => hash {
      field years => 1; field days => 366; field rdays => 1; end()
    };
  }, 'Date arithmetic (2)');
}

#--- special cases -------------------------------------------------------------

{ # special cases: FTF today; age should be undefined and held should be 0
  my $c = $t->app->myfind(
    found => Time::Moment->now->at_midnight,
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Find';
    call age => U();
    call held => hash {
      field years => 0; field days => 0; field rdays => 0; end()
    };
  }, 'Special case 1: FTF find / held')
}

{ # special cases: FTF 100 days ago; age should be undefined and held should be
  # 100
  my $c = $t->app->myfind(
    found => Time::Moment->now->at_midnight->plus_days(-100),
  );
  is($c, object {
    prop blessed => 'MyCaches::Model::Find';
    call age => U();
    call held => hash {
      field years => 0; field days => 100; field rdays => 100; end()
    };
  }, 'Special case 2: FTF find / held')
}

{ # special cases: no next find ("held")
  my $c = $t->app->find(
    prev => Time::Moment->now->at_midnight->plus_days(-200),
    found => Time::Moment->now->at_midnight->plus_days(-100),
  );
  is($c, object {
    call age => hash {
      field years => 0; field days => 100; field rdays => 100; end()
    };
    call held => hash {
      field years => 0; field days => 100; field rdays => 100; end()
    };
  }, 'Special case 3: Held find / held');
}

#--- database operations -------------------------------------------------------

{ # create an entry
  my $c = $t->app->find(
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
  ok(lives { $c->create}, 'Create entry') or diag($@);
  is($c->id, 1, 'New entry row id');

  { # load the entry by row id
    my $d = $t->app->find(
      load => { id => $c->id }
    );
    is($d, object {
      prop blessed => 'MyCaches::Model::Find';
      call id => 1;
      call cacheid => 'GC9ABCD';
      call name => 'Žluťoučký kůň 🐴';
      call difficulty => 5;
      call terrain => 4.5;
      call ctype => 4;
      call gallery => 1;
      call status => 1;
      call prev => Time::Moment->from_string('2019-01-19T00:00' . $d->tz);
      call found => Time::Moment->from_string('2019-01-19T00:00' . $d->tz);
      call next => Time::Moment->from_string('2019-01-19T00:00' . $d->tz);
      call favorite => 1;
      call xtf => 1;
      call logid => 'abcdef-012';
      call age => hash {
        field years => 0; field days => 0; field rdays => 0; end()
      };
      call held => hash {
        field years => 0; field days => 0; field rdays => 0; end()
      };
    }, 'Loaded entry check (by id)');
  }

  { # load the entry by cacheid
    my $d = $t->app->find(
      load => { cacheid => 'GC9ABCD' }
    );
    is($d, object {
      prop blessed => 'MyCaches::Model::Find';
      call id => 1;
      call cacheid => 'GC9ABCD';
      call name => 'Žluťoučký kůň 🐴';
      call difficulty => 5;
      call terrain => 4.5;
      call ctype => 4;
      call gallery => 1;
      call status => 1;
      call prev => Time::Moment->from_string('2019-01-19T00:00' . $d->tz);
      call found => Time::Moment->from_string('2019-01-19T00:00' . $d->tz);
      call next => Time::Moment->from_string('2019-01-19T00:00' . $d->tz);
      call favorite => 1;
      call xtf => 1;
      call logid => 'abcdef-012';
      call age => hash {
        field years => 0; field days => 0; field rdays => 0; end()
      };
      call held => hash {
        field years => 0; field days => 0; field rdays => 0; end()
      };
    }, 'Loaded entry check (by cacheid)');

    # check finding the next row id
    $d->get_new_id;
    is($d->id, 2, 'Getting new rowid');
  }

  # update
  $c->{name} = 'Pěl ďábelské ódy'; # bypassing r/o accessor
  ok(lives { $c->update }, 'Update entry') or diag($@);

  { # check updated entry
    my $e = $t->app->find(
      load => { id => $c->id }
    );
    is($e, object {
      prop blessed => 'MyCaches::Model::Find';
      call name => string 'Pěl ďábelské ódy';
    }, 'Verify updated entry')  ;
  }

  # delete entry
  ok(lives { $c->delete }, 'Delete entry') or diag($@);
  like(dies {
    $t->app->find(load => { cacheid => 'GC9ABCD' });
  }, qr/Find \w+ not found/, 'Deleted entry retrieval');

  # delete this entry again, this should fail
  like(dies {
    $c->delete
  }, qr/Find \d+ not found/, 'Deleting non-existent entry');

  # updating non-existent entry should fail too
  like(dies {
    $c->update
  }, qr/Find \d+ not found/, 'Updating non-existent entry');
}

#--- finish --------------------------------------------------------------------

done_testing;
