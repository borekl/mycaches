package MyCaches;
use Mojo::Base 'Mojolicious', -signatures;

sub startup($self)
{
  my $r = $self->routes;

  $self->helper(sqlite => sub {
    state $sql = Mojo::SQLite->new('mycaches.sqlite')
  });

  $r->get('/')->to('cachelist#list', finds => {}, hides => {});
  $r->get('/finds')->to('cachelist#list', finds => {}, hides => undef);
  $r->get('/hides')->to('cachelist#list', hides => {}, finds => undef);
}

1;
