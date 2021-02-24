package MyCaches;

use Mojo::Base 'Mojolicious', -signatures;
use MyCaches::Helpers;
use Mojo::SQLite;


sub startup($self)
{
  #--- config defaults

  $self->plugin('Config', default => { dbfile => 'mycaches' });

  #--- database setup

  $self->helper(sqlite => sub {
    state $sql = Mojo::SQLite->new($self->config('dbfile') . '.sqlite')
  });

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

  my $finds = $r->get('/finds')->to('cachelist#list', finds => 1);
  $finds->get->to;
  $finds->get('/limit/:limit')->to;
  $finds->get('/archived')->to(archived => 1);

  $finds->get('/:id')->to('cachelist#find');

  #--- hides ------------------------------------------------------------------

  my $hides = $r->get('/hides')->to('cachelist#list', hides => 1);
  $hides->get->to;

  $hides->get('/:id')->to('cachelist#hide');

}


1;
