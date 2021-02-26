package MyCaches::Command::users;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::Util qw(getopt);

use MyCaches::Model::Users;

has description => 'Manage authorized users';
has uage => <<EOHD;
Usage: APPLICATION users [OPTIONS]
-l,--list  list users
EOHD

sub run ($self, @args)
{
  my $db = $self->app->sqlite->db;

  #parse arguments
  getopt \@args,
    'l|list'       => \my $cmd_list,
    'a|add=s'      => \my $cmd_add,
    'u|update=s'   => \my $cmd_update,
    'd|delete=s'   => \my $cmd_delete,
    'p|password=s' => \my $cmd_pw;

  # show list of users
  if($cmd_list) {
    my @list = MyCaches::Model::User->new(db => $db)->list;
    if(@list) {
      say 'Authorized users:';
      say join(', ', @list);
    } else {
      say 'No authorized users found';
    }
  }

  # add new user
  if($cmd_add) {
    MyCaches::Model::User->new(
      db => $db,
      userid => $cmd_add,
      pw => $cmd_pw // ''
    )->create;
    say "User $cmd_add created";
  }

  # update user
  if($cmd_update) {
    MyCaches::Model::User->new(
      db => $db,
      userid => $cmd_update,
      pw => $cmd_pw // ''
    )->update;
    say "User $cmd_update updated";
  }

  # delete user
  if($cmd_delete) {
    MyCaches::Model::User->new(
      db => $db,
      userid => $cmd_delete
    )->delete;
    say "User $cmd_delete deleted";
  }
}


1;
