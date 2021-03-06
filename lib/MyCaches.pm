package MyCaches;

use Mojo::Base 'Mojolicious', -signatures;
use MyCaches::Helpers;
use Mojo::SQLite;


sub startup($self)
{

  #--- hook to set url base for reverse proxied requests (thanks go to mst)

  $self->hook(before_dispatch => sub ($c) {
    if (my $path = $c->req->headers->header('X-Forwarded-Path')) {
      $c->req->url->base->path->parse($path)->trailing_slash(1);
    };
  });

  #--- config defaults

  $self->plugin('Config', default => { dbfile => 'mycaches' });

  #--- secrets

  $self->secrets($self->config('secrets'));

  #--- database setup

  $self->helper(sqlite => sub {
    state $sql = Mojo::SQLite->new($self->config('dbfile') . '.sqlite')
  });

  my $path = $self->home->child('migrations', 'mycaches.sql');
  $self->sqlite->auto_migrate(1)->migrations->name('mycaches')->from_file($path);

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

  #--- finds/hides section (unauthorized)

  my $finds = $r->any('/finds')->to('cachelist#list', finds => 1);
  my $hides = $r->any('/hides')->to('cachelist#list', hides => 1);

  #--- authorized -------------------------------------------------------------

  my $auth = $r->under('/' => sub ($c) {
    return 1 if $c->session('user');
    $c->render(text => "Unauthorized.", status => 401);
    return undef;
  });

  my $finds_auth = $auth->any('/finds' => { entity => 'find'});
  my $hides_auth = $auth->any('/hides' => { entity => 'hide'});

  #--- login page -------------------------------------------------------------

  $r->get('/login')->to('login#index');
  $r->post('/login')->to('login#login');
  $r->any('/logout')->to('login#logout');

  #--- finds ------------------------------------------------------------------

  $finds->get->to;
  $finds->get('/limit/:limit')->to;
  $finds->get('/archived')->to(archived => 1);

  $finds_auth->get('/:id/delete')->to('cachelist#delete');
  $finds_auth->get('/:id')->to('cachelist#find');
  $finds_auth->post('/:id')->to('cachelist#save');
  $finds_auth->post('/')->to('cachelist#save');

  #--- hides ------------------------------------------------------------------

  $hides->get->to;
  $hides_auth->get('/:id/delete')->to('cachelist#delete');
  $hides_auth->get('/:id')->to('cachelist#hide');
  $hides_auth->post('/:id')->to('cachelist#save');
  $hides_auth->post('/')->to('cachelist#save');

}


1;
