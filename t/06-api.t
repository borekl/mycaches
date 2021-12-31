#!/usr/bin/perl

# Test the REST API v1

use utf8;
use Mojo::Base -strict;
use Test::Mojo;
use Test::Most;
use Path::Tiny qw(tempfile);
use MyCaches::Model::Users;

my $user = 'testuser',
my $pw = 'testPa$$w0rd';

# instantiate the app and create test user
my $t = Test::Mojo->new('MyCaches', {
  dbfile => tempfile, secrets => [ 'abc123']
});
my $u = MyCaches::Model::Users->new(
  db => $t->app->sqlite->db,
  userid => $user,
  pw => $pw,
);
lives_ok { $u->create } 'User creation';

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

#--- finish --------------------------------------------------------------------

done_testing();
