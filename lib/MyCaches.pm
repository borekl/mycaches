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

  #--- authorized -------------------------------------------------------------

  my $auth = $r->under('/' => sub ($c) {
    return 1 if $c->session('user');
    $c->render(text => "Unauthorized.", status => 401);
    return undef;
  });

  #--- front page -------------------------------------------------------------

  $r->get('/')->to('cachelist#list', finds => 1, hides => 1);

  #--- login page -------------------------------------------------------------

  $r->get('/login')->to('login#index');
  $r->post('/login')->to('login#login');
  $r->any('/logout')->to('login#logout');

  #--- finds ------------------------------------------------------------------

  my $finds = $r->any('/finds')->to('cachelist#list', finds => 1);
  my $finds_auth = $auth->any('/finds' => { entity => 'find'});

  $finds->get->to;
  $finds->get('/limit/:limit')->to;
  $finds->get('/archived')->to(archived => 1);

  $finds_auth->get('/:id')->to('cachelist#find');
  $finds_auth->post('/:id')->to('cachelist#save');
  $finds_auth->post('/')->to('cachelist#save');

  #--- hides ------------------------------------------------------------------

  my $hides = $r->any('/hides')->to('cachelist#list', hides => 1);
  my $hides_auth = $auth->any('/hides' => { entity => 'hide'});

  $hides->get->to;

  $hides_auth->get('/:id')->to('cachelist#hide');
  $hides_auth->post('/:id')->to('cachelist#save');
  $hides_auth->post('/')->to('cachelist#save');

}


1;
