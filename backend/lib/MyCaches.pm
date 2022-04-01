package MyCaches;

our $VERSION = '0.01';

use Mojo::Base 'Mojolicious', -signatures;
use MyCaches::Helpers;
use MyCaches::Model::Users;
use MyCaches::Model::Find;
use MyCaches::Model::Hide;
use Mojo::SQLite;

sub startup($self)
{

  # hook to set url base for reverse proxied requests (thanks go to mst)
  $self->hook(before_dispatch => sub ($c) {
    if (my $path = $c->req->headers->header('X-Forwarded-Path')) {
      $c->req->url->base->path->parse($path)->trailing_slash(1);
    };
  });

  # config defaults
  $self->plugin('Config', default => { dbfile => 'mycaches.sqlite' });

  # secrets
  $self->secrets($self->config('secrets'));

  # database connection setup
  $self->helper(sqlite => sub {
    state $sql = Mojo::SQLite->new($self->config('dbfile'))
  });

  # enable foreign keys feature (in SQLite off by default)
  $self->sqlite->on(connection => sub ($sql, $dbh) {
    $dbh->do('pragma foreign_keys = on');
  });

  # perform migrations (ie. upgrade the database schema to the most recent
  # version)
  my $path = $self->home->child('migrations', 'mycaches.sql');
  $self->sqlite->auto_migrate(1)->migrations->name('mycaches')->from_file($path);

  # custom commands
  push @{$self->commands->namespaces}, 'MyCaches::Command';

  # register custom tag helpers
  MyCaches::Helpers->register($self);

  # stash defaults
  $self->defaults(
    limit => 0,
    archived => 0,
    finds => undef,
    hides => undef,
  );

  #--- MODEL -------------------------------------------------------------------

  $self->helper(user => sub {
    MyCaches::Model::Users->new(sqlite => shift->sqlite, @_)
  });

  $self->helper(myfind => sub {
    MyCaches::Model::Find->new(sqlite => shift->sqlite, @_)
  });

  $self->helper(myhide => sub {
    MyCaches::Model::Hide->new(sqlite => shift->sqlite, @_)
  });

  #--- ROUTES ------------------------------------------------------------------

  # get route object
  my $r = $self->routes;

  # front page
  $r->get('/')->to('caches#list', finds => 1, hides => 1);

  # finds/hides section (unauthorized)
  my $finds = $r->any('/finds')->to('caches#list', finds => 1);
  my $hides = $r->any('/hides')->to('caches#list', hides => 1);

  # authorized
  my $auth = $r->under('/' => sub ($c) {
    return 1 if $c->session('user');
    $c->render(text => "Unauthorized.", status => 401);
    return undef;
  });

  my $finds_auth = $auth->any('/finds' => { entity => 'find'});
  my $hides_auth = $auth->any('/hides' => { entity => 'hide'});

  # login page
  $r->get('/login')->to('login#index');
  $r->post('/login')->to('login#login');
  $r->any('/logout')->to('login#logout');

  # finds
  $finds->get->to;
  $finds->get('/limit/:limit')->to;
  $finds->get('/archived')->to(archived => 1);

  $finds_auth->get('/:id/delete')->to('caches#delete');
  $finds_auth->get('/:id')->to('caches#find');
  $finds_auth->post('/:id')->to('caches#save');
  $finds_auth->post('/')->to('caches#save');

  # hides
  $hides->get->to;
  $hides_auth->get('/:id/delete')->to('caches#delete');
  $hides_auth->get('/:id')->to('caches#hide');
  $hides_auth->post('/:id')->to('caches#save');
  $hides_auth->post('/')->to('caches#save');

  # API routes
  my $api = $auth->any('/api/v1')->to(controller => 'API');
  $api->get->to('API#api');

  my $api_hides = $api->any('/hides')->to(table => 'hides');
  $api_hides->post('/')->to('API#add');
  $api_hides->get('/:id')->to('API#load');
  $api_hides->put('/:id')->to('API#update');
  $api_hides->delete('/:id')->to('API#delete');

  $api_hides->post('/:id/logs/')->to('API#add_log');
  $api_hides->put('/:id/logs/:logid')->to('API#update_log');
  $api_hides->delete('/:id/logs/:logid')->to('API#delete_log');

  my $api_finds = $api->any('/finds')->to(table => 'finds');
  $api_finds->post('/')->to('API#add');
  $api_finds->get('/:id')->to('API#load');
  $api_finds->put('/:id')->to('API#update');
  $api_finds->delete('/:id')->to('API#delete');

}


1;
