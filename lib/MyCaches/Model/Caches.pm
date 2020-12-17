package MyCaches::Model::Caches;

use Mojo::Base -base, -signatures;

has 'db';

#------------------------------------------------------------------------------
# Get a cache list; additional arguments accepted for additional filtering:
#   'tail' - get only last N entries
#   'archived' - get only archived entries
#------------------------------------------------------------------------------

sub list($self, %arg)
{
  my $where;
  $where = { archived => 1 } if($arg{archived});
  my $list = $self->db->select($arg{table}, undef, $where)->hashes;

  if($arg{tail}) {
    return $list->tail($arg{tail});
  } else {
    return $list;
  }
}


1;
