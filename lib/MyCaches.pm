package MyCaches;

use Mojo::Base 'Mojolicious', -signatures;
use Mojo::SQLite;


sub startup($self)
{
  #--- config defaults

  $self->plugin('Config', default => { dbfile => 'mycaches' });

  #--- database setup

  $self->helper(sqlite => sub {
    state $sql = Mojo::SQLite->new($self->config('dbfile') . '.sqlite')
  });

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
  #--- front page -------------------------------------------------------------
  #----------------------------------------------------------------------------

  $r->get('/')->to('cachelist#list', finds => 1, hides => 1);

  #----------------------------------------------------------------------------
  #--- list finds -------------------------------------------------------------
  #----------------------------------------------------------------------------

  my $finds = $r->get('/finds')->to('cachelist#list', finds => 1);
  $finds->get->to;
  $finds->get('/limit/:limit')->to;
  $finds->get('/archived')->to(archived => 1);

  #----------------------------------------------------------------------------
  #--- list hides -------------------------------------------------------------
  #----------------------------------------------------------------------------

  $r->get('/hides')->to('cachelist#list', hides => 1);
}


1;
