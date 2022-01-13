#!/usr/bin/perl

# Test MyCaches::Model::Users

use Mojo::Base -strict;
use Test2::V0;
use Test2::MojoX;

my $t = Test2::MojoX->new('MyCaches', { dbfile => ':temp:' });

# test instance creation
my $u = $t->app->user(
  userid => 'testuser',
  pw => 'testPa$$w0rd',
);
isa_ok($u, 'MyCaches::Model::Users');

# do we have database instance
isa_ok($u->sqlite, 'Mojo::SQLite');

# test if hash was created successfully
like($u->hash, qr/\$argon2/, 'Hash generation');

# create user in database
ok(lives { $u->create }, 'User creation') or diag($@);

# create duplicate user
like(dies { $u->create }, qr/UNIQUE constraint/i, 'Duplicate user creation');

# check user
ok(lives { $u->check }, 'User check') or diag($@);
is($u->check, 1, 'User check positive match');
$u->pw('SomethingElse');
is($u->check, 0, 'User check negative match');

# update user in database
my $v = $t->app->user(
  userid => 'testuser',
  pw => $u->pw,
);
ok(lives { $v->update }, 'User update') or diag($@);

# check updated users
is($v->check, 1, 'User check positive match after update');

# list users
my @userlist = $v->list;
is(@userlist, 1, 'User list size');
is($userlist[0], 'testuser', 'User list content');

# delete user
ok(lives { $v->delete }, 'User deletion') or diag($@);
@userlist = $v->list;
is(@userlist, 0, 'User list size after deletion');

# check fails after deletion
is($v->check, 0, 'User check negative after deletion');

# finish
done_testing;
