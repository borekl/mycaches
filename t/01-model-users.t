#!/usr/bin/perl

# Test MyCaches::Model::Users

use Mojo::Base -strict;
use Test::Mojo;
use Test::Most;
use Path::Tiny qw(tempfile);
use MyCaches::Model::Users;

my $t = Test::Mojo->new('MyCaches', { dbfile => tempfile });

# test instance creation
my $u = MyCaches::Model::Users->new(
  db => $t->app->sqlite->db,
  userid => 'testuser',
  pw => 'testPa$$w0rd',
);

isa_ok($u, 'MyCaches::Model::Users');

# test if hash was created successfully
like($u->hash, qr/\$argon2/, 'Hash generation');

# create user in database
lives_ok { $u->create } 'User creation';

# create duplicate user
throws_ok { $u->create } qr/UNIQUE constraint/i, 'Duplicate user creation';

# check user
lives_ok { $u->check } 'User check';
is($u->check, 1, 'User check positive match');

$u->pw('SomethingElse');
is($u->check, 0, 'User check negative match');

# update user in database
my $v = MyCaches::Model::Users->new(
  db => $t->app->sqlite->db,
  userid => 'testuser',
  pw => $u->pw,
);
lives_ok { $v->update } 'User update';

# check updated users
is($v->check, 1, 'User check positive match after update');

# list users
my @userlist = $v->list;
is(@userlist, 1, 'User list size');
is($userlist[0], 'testuser', 'User list content');

# delete user
lives_ok { $v->delete } 'User deletion';
@userlist = $v->list;
is(@userlist, 0, 'User list size after deletion');

# check fails after deletion
is($v->check, 0, 'User check negative after deletion');

# finish
done_testing();
