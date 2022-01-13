package MyCaches::Command::users;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::Util qw(getopt);

has description => 'Manage authorized users';
has usage => <<EOHD;
Usage: APPLICATION users [OPTIONS]
-l,--list         list users
-a,--add USER     add new user
-u,--update USER  update existing user's password
-d,--delete USER  remove existing user
-p,--password PW  specify password
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
    my @list = $self->app->user->list;
    if(@list) {
      say 'Authorized users:';
      say join(', ', @list);
    } else {
      say 'No authorized users found';
    }
  }

  # add new user
  if($cmd_add) {
    $self->app->user(userid => $cmd_add, pw => $cmd_pw // '')->create;
    say "User $cmd_add created";
  }

  # update user
  if($cmd_update) {
    $self->app->user(userid => $cmd_update, pw => $cmd_pw // '')->update;
    say "User $cmd_update updated";
  }

  # delete user
  if($cmd_delete) {
    $self->app->user(userid => $cmd_delete)->delete;
    say "User $cmd_delete deleted";
  }
}


1;
