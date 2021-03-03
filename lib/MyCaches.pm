package MyCaches;

use Mojo::Base 'Mojolicious', -signatures;
use MyCaches::Helpers;
use Mojo::SQLite;


sub startup($self)
{
  #--- config defaults

  $self->plugin('Config', default => { dbfile => 'mycaches' });

  #--- secrets

  $self->secrets($self->config('secrets'));

  #--- database setup

  $self->helper(sqlite => sub {
    state $sql = Mojo::SQLite->new($self->config('dbfile') . '.sqlite')
  });

  #--- custom commands

  push @{$self->commands->namespaces}, 'MyCaches::Command';

  #--- register custom tag helpers

  MyCaches::Helpers->register($self);

  #--- stash defaults

  $self->defaults(
    limit => 0,
    archived => 0,
    finds => undef,
    hides => undef,
  );

  #--- get route object

  my $r = $self->routes;

  #----------------------------------------------------------------------------
  #--- ROUTES -----------------------------------------------------------------
  #----------------------------------------------------------------------------

  #--- front page -------------------------------------------------------------

  $r->get('/')->to('cachelist#list', finds => 1, hides => 1);

  #--- finds ------------------------------------------------------------------

  my $finds = $r->any('/finds')->to('cachelist#list', finds => 1);
  $finds->get->to;
  $finds->get('/limit/:limit')->to;
  $finds->get('/archived')->to(archived => 1);

  $finds->get('/:id')->to('cachelist#find');
  $finds->post('/:id')->to('cachelist#save', entity => 'find');
  $finds->post('/')->to('cachelist#save', entity => 'find');

  #--- hides ------------------------------------------------------------------

  my $hides = $r->any('/hides')->to('cachelist#list', hides => 1);
  $hides->get->to;

  $hides->get('/:id')->to('cachelist#hide');
  $hides->post('/:id')->to('cachelist#save', entity => 'hide');
  $hides->post('/')->to('cachelist#save', entity => 'hide');

}


1;
