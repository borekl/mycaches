#!/usr/bin/perl

# Test the REST API v1

use utf8;
use strict;
use warnings;
use Test2::V0;
use Test2::MojoX;
use experimental 'signatures';

my $user = 'testuser',
my $pw = 'testPa$$w0rd';

#--- testing data --------------------------------------------------------------

sub checker (%h) { return hash { field $_ => $h{$_} for keys %h; etc; } }

my $check_hide = checker(my %hide = (
  cacheid => 'GC9ABCD', name => 'Žluťoučký kůň 🐴',
  difficulty => 5, terrain => 4.5, ctype => 4, gallery => 1,
  published => '2018-12-18',  found => '2019-12-18',
  finds => 321, status => 1,
));

my $check_hide_upd = checker(my %hide_upd = (
  cacheid => 'GC9EFGH', name => 'Pěl ďábelské ódy 🐴',
  difficulty => 4, terrain => 1.5, ctype => 2, gallery => 0,
  published => '2019-12-18',  found => '2020-12-18',
  finds => 456, status => 2,
));

my $check_find = checker(my %find = (
  cacheid => 'GC9ABCD', name => 'Žluťoučký kůň 🐴',
  difficulty => 5, terrain => 4.5, ctype => 4, gallery => 1,
  prev => '2019-11-18', found => '2019-12-18', next => '2020-12-18',
  favorite => 1, xtf => 1, logid => 'abcdef-123', status => 1,
));

my $check_find_upd = checker(my %find_upd = (
  cacheid => 'GC9EFGH', name => 'Pěl ďábelské ódy 🐴',
  difficulty => 4, terrain => 1.5, ctype => 2, gallery => 0,
  prev => '2019-10-18', found => '2019-11-18', next => '2020-11-18',
  favorite => 0, xtf => 0, logid => 'abcdef-456', status => 0,
));

#--- basic setup ---------------------------------------------------------------

# instantiate the app
my $t = Test2::MojoX->new('MyCaches', {
  dbfile => ':temp:', secrets => [ 'abc123']
});

# create test user
my $u = $t->app->user(userid => $user, pw => $pw);
ok(lives { $u->create }, 'User creation') or diag($@);

#--- API authorization ---------------------------------------------------------

# unauthorized request should fail with 401 Unauthorized
$t->get_ok('/api/v1')->status_is(401);

# log into the app
$t->ua->max_redirects(0);
$t->post_ok('/login', form => { user => $user, pass => $pw })
  ->status_is(302);

# authorized request should succeed
$t->get_ok('/api/v1')
  ->status_is(200)
  ->json_is('/status' => 'ok')
  ->json_is('/user' => $user);

#--- hides ---------------------------------------------------------------------

# attempt to retrieve non-existent entry
$t->get_ok('/api/v1/hides/1')
  ->status_is(404);

# attempt to delete non-existent entry
$t->delete_ok('/api/v1/hides/1')
  ->status_is(404);

# create new entry
$t->post_ok('/api/v1/hides', json => \%hide)
  ->status_is(201)
  ->json_is('/id' => 1);

# retrieve the entry
$t->get_ok('/api/v1/hides/1')
  ->status_is(200);
is($t->tx->res->json, $check_hide, 'Verify created entry');

# update the entry
$t->put_ok('/api/v1/hides/1', json => \%hide_upd)
  ->status_is(204);

# retrieve and check updated entry
$t->get_ok('/api/v1/hides/1')
  ->status_is(200);
is($t->tx->res->json, $check_hide_upd, 'Verify updated entry');

# delete the entry
$t->delete_ok('/api/v1/hides/1')
  ->status_is(204);

# deleting non-existent entry should fail
$t->delete_ok('/api/v1/hides/1')
  ->status_is(404);

# updating non-existent entry should fail
$t->put_ok('/api/v1/hides/1', json => \%hide_upd)
  ->status_is(404);

#--- finds ---------------------------------------------------------------------

# attempt to retrieve non-existent entry
$t->get_ok('/api/v1/finds/1')
  ->status_is(404);

# attempt to delete non-existent entry
$t->delete_ok('/api/v1/finds/1')
  ->status_is(404);

# create new entry
$t->post_ok('/api/v1/finds', json => \%find)
  ->status_is(201)
  ->json_is('/id' => 1);

# retrieve the entry
$t->get_ok('/api/v1/finds/1')
  ->status_is(200);
is($t->tx->res->json, $check_find, 'Verify created entry');

# update the entry
$t->put_ok('/api/v1/finds/1', json => \%find_upd)
  ->status_is(204);

# retrieve and check updated entry
$t->get_ok('/api/v1/finds/1')
  ->status_is(200);
is($t->tx->res->json, $check_find_upd, 'Verify updated entry');

# delete the entry
$t->delete_ok('/api/v1/finds/1')
  ->status_is(204);

# deleting non-existent entry should fail
$t->delete_ok('/api/v1/finds/1')
  ->status_is(404);

# updating non-existent entry should fail
$t->put_ok('/api/v1/finds/1', json => \%find_upd)
  ->status_is(404);

#--- finish --------------------------------------------------------------------

done_testing();
