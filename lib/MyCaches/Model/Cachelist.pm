package MyCaches::Model::Cachelist;

use Mojo::Base -base, -signatures;
use MyCaches::Model::Find;
use MyCaches::Model::Hide;

has 'caches' => sub {[]};
has 'db';

#------------------------------------------------------------------------------
# Get a cache list; additional arguments accepted for additional filtering:
#   'table' - db table to get entries from
#   'tail' - get only last N entries
#   'where' - where clause
#------------------------------------------------------------------------------

sub load($self, %arg)
{
  my $db = $self->db;
  my $where = $arg{where} // undef;
  my $order = { -desc => $arg{table} . '_i' };

  my $result = $db->select($arg{table}, undef, $where, $order);

  my @caches;

  while(my $row = $result->hash) {
    my $cache;
    $cache = MyCaches::Model::Find->new(entry => $row) if exists $row->{finds_i};
    $cache = MyCaches::Model::Hide->new(entry => $row) if exists $row->{hides_i};
    push(@caches, $cache);
  }

  if($arg{tail}) {
    @caches = @caches[$#caches-$arg{tail}+1 .. $#caches];
  }

  $self->caches(\@caches);
  return $self;
}

#------------------------------------------------------------------------------
# Return the list as arrayref of hashes
#------------------------------------------------------------------------------

sub to_hash($self)
{
  my @data;

  foreach my $entry (@{$self->caches}) {
    push(@data, $entry->to_hash);
  }

  return \@data;
}

#------------------------------------------------------------------------------

1;
