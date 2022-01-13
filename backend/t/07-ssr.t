#!/usr/bin/perl

# Test server-side rendered pages

use utf8;
use strict;
use warnings;
use Test2::V0;
use Test2::MojoX;
use experimental 'signatures';

#--- basic setup ---------------------------------------------------------------

# credentials
my $user = 'testuser',
my $pw = 'testPa$$w0rd';

# instantiate the app
my $t = Test2::MojoX->new('MyCaches', {
  dbfile => ':temp:', secrets => [ 'abc123']
});

# create test user
my $u = $t->app->user(userid => $user, pw => $pw);
ok(lives { $u->create }, 'User creation') or diag($@);

#--- login form ----------------------------------------------------------------

# is the form ok?
$t->get_ok('/login')
  ->status_is(200)
  ->text_like('header' => qr/Please log in…/)
  ->element_exists('input[name="user"]')
  ->element_exists('input[name="pass"]')
  ->element_exists('button[type="submit"]')
  ->element_exists('button[type="reset"]');

# invalid login is invalid
$t->post_ok('/login', form => { user => 'wronguser', pass => 'wrongpass'})
  ->status_is(401);
$t->post_ok('/login', form => { user => $user, pass => 'wrongpass'})
  ->status_is(401);

# log into the app
$t->ua->max_redirects(1);
$t->post_ok('/login', form => { user => $user, pass => $pw })
  ->status_is(200)
  ->text_like('header', qr/logged in as/)
  ->text_is('header span', $user);

# logout (Referer field must be specified as it is used by the controller code)
$t->ua->max_redirects(1);
$t->get_ok('/logout' => { Referer => '/' })
  ->status_is(200)
  ->text_unlike('header', qr/logged in as/);

#--- finds/hides ---------------------------------------------------------------

# at this moment just test that the basic pages load
$t->get_ok('/')->status_is(200);
$t->get_ok('/hides')->status_is(200);
$t->get_ok('/finds')->status_is(200);

#--- finish --------------------------------------------------------------------

done_testing();
