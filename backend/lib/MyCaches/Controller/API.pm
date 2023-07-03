package MyCaches::Controller::API;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Feature::Compat::Try;

#-------------------------------------------------------------------------------
# Return appropriate model instance according to the 'table' stash value
sub _inst ($c, @args)
{
  my $table = $c->stash('table');
  if($table eq 'hides') {
    return $c->myhide(@args);
  } elsif($table eq 'finds') {
    return $c->myfind(@args);
  } else {
    die 'Wrong db table specified';
  }
}

#-------------------------------------------------------------------------------
# Simple NOOP endpoint, suitable for verifying that user is authenticated
sub api ($self)
{
  $self->render(json => { status => 'ok', user => $self->session('user') });
}

#-------------------------------------------------------------------------------
sub add ($c)
{
  try {
    my $inst = $c->_inst($c->req->json->%*);
    $inst->create;
    $c->render(status => 201, json => { id => $inst->id });
  } catch($e) {
    $c->render(status => 500, json => { error => $e });
  }
}

#-------------------------------------------------------------------------------
# load single 'find' or 'hide' entry specified by stash value 'id'; special
# value of 'new' will make this function return default instance instead of
# loading anything from the database; special value of 'last' will make this
# function return the last entry; for entries loaded from database, this
# function also supplies 'last' key, which lets the client know whether the
# entry returned is the last one
sub load ($c)
{
  try {
    my ($inst, $last_id, $h);
    if($c->stash('id') eq 'new') {
      $inst = $c->_inst();
    } elsif($c->stash('id') eq 'last') {
      my $temp_inst = $c->_inst();
      $last_id = $temp_inst->get_last_id;
      $inst = $c->_inst(load => { id => $last_id });
    } else {
      $inst = $c->_inst(load => { id => $c->stash('id') });
      $last_id = $inst->get_last_id;
    }
    $h = $inst->hash_for_client;
    # 'last' key indicates whether the entry loaded from the database is the
    # last one; this requires strict ordering of the rowid fields
    if(defined $last_id) { $h->{last} = ($inst->id == $last_id ? \1 : \0) }
    $c->render(status => 200, json => $h);
  } catch($e) {
    my $code = 500;
    $code = 404 if $e =~ /\w+ \d+ not found/;
    $c->render(status => $code, json => { error => $e });
  }
}

#-------------------------------------------------------------------------------
sub update ($c)
{
  try {
    my $inst = $c->_inst($c->req->json->%*, id => $c->stash('id'));
    $inst->update;
    $c->rendered(204);
  } catch($e) {
    my $code = 500;
    $code = 404 if $e =~ /\w+ \d+ not found/;
    $c->render(status => $code, json => { error => $e });
  }
}

#-------------------------------------------------------------------------------
sub delete ($c)
{
  try {
    my $inst = $c->_inst(load => { id => $c->stash('id') });
    $inst->delete;
    $c->rendered(204);
  } catch($e) {
    my $code = 500;
    $code = 404 if $e =~ /\w+ \d+ not found/;
    $c->render(status => $code, json => { error => $e });
  }
}

1;
