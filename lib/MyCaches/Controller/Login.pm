package MyCaches::Controller::Login;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use MyCaches::Model::Users;

sub index ($c)
{
  if(!$c->session('user')) {
    $c->render;
  } else {
    $c->render(text => 'Already logged in');
  }
}

sub login ($c)
{
  my $usr = MyCaches::Model::Users->new(
    db => $c->sqlite->db,
    userid => $c->param('user'),
    pw => $c->param('pass')
  );

  if($c->session('user')) {
    $c->render(text => 'Already logged in as ' . $c->session('user'));
  } elsif($usr->check) {
    $c->session(
      user => $usr->userid,
      expiration => $c->config('session_exp') // 86400
    );
    # FIXME: We need to return to where the user came from
    #$c->redirect_to($c->url_for('/'))
    $c->redirect_to($c->url_for('/')->tap(sub ($url) {
      $url->path->trailing_slash(1)
    }));
  } else {
    $c->render(text => "Auth failed");
  }
}

sub logout ($c)
{
  if($c->session('user')) {
    $c->session(expires => 1);
  }
  $c->redirect_to($c->req->headers->referrer);
}

1;
