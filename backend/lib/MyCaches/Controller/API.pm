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
sub load ($c)
{
  try {
    my $inst = $c->_inst(load => { id => $c->stash('id') });
    $c->render(status => 200, json => $inst->to_hash);
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
