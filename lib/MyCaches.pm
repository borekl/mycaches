package MyCaches;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::SQLite;

sub startup($self)
{
  $self->plugin('Config', default => { dbfile => 'mycaches' });

  $self->helper(sqlite => sub {
    state $sql = Mojo::SQLite->new($self->config('dbfile') . '.sqlite')
  });

  my $r = $self->routes;

  $r->get('/')->to('cachelist#list', finds => {}, hides => {});
  $r->get('/finds')->to('cachelist#list', finds => {}, hides => undef);
  $r->get('/hides')->to('cachelist#list', hides => {}, finds => undef);
}

1;
