package MyCaches::Model::Loglist;

use Mojo::Base 'Mojo::Collection', -signatures;
use MyCaches::Model::Log;

sub load ($class, $db, %arg)
{
  my $coll = $class->SUPER::new();

  my $re = $db->select('logs', undef, \%arg, { -asc => [ 'date', 'seq' ]});
  while(my $row = $re->hash) {
    push(@$coll, MyCaches::Model::Log->new(db => $db, entry => $row));
  }
  $re->finish;

  return $coll;
}

1;
