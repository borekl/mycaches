package MyCaches::Model::Hide;

# class representing single find, based off Cache class

use Moo;
extends 'MyCaches::Model::Cache';
use experimental 'signatures';
use MyCaches::Types::Date;
use POSIX qw(strftime);

# publication date
has 'published' => (
  is => 'rwp',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# number of finds / note that this is not a field in the backend 'hides' table
# but an aggregate number of 'found it' logs in the 'logs' table
has 'finds' => (
  is => 'rwp', default => 0,
  coerce => sub ($v) { int($v) },
);
# last find date
has 'found' => (
  is => 'rwp',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# age, or days since last find (or publication date if unfound)
has 'age' => (
  is => 'lazy',
  default => sub ($self) {
    my $ref1 = $self->found // $self->published;
    return $self->calc_years_days($ref1, $self->now);
  }
);

#-------------------------------------------------------------------------------
# return instance data as a hash, suitable for sending to database
sub hash_for_db ($self)
{
  my $data = $self->SUPER::hash_for_db;

  $data->{hides_i} = $self->id;
  $data->{published} = $self->published->strftime('%F') if $self->published;
  $data->{finds} = $self->finds;
  $data->{found} = $self->found ? $self->found->strftime('%F') : undef;

  return $data;
}

#-------------------------------------------------------------------------------
# return instance data as a hash, transformed and filled in with fields suitable
# for client
sub hash_for_client ($self)
{
  my $data = $self->SUPER::hash_for_client;
  $data->{age} = $self->age;
  return $data;
}

#-------------------------------------------------------------------------------
# set instance attributes from a database row
sub set_from_db_row ($self, %e)
{
  $self->SUPER::set_from_db_row(%e);
  $self->_set_id($e{hides_i});
  $self->_set_published($e{published});
  $self->_set_finds($e{finds});
  $self->_set_found($e{found});
  return $self;
}

#-------------------------------------------------------------------------------
# load single entry specified either by rowid ('id') or cacheid; defined but
# false rowid (ie. id == 0) will load the highest rowid entry
sub load ($self, %arg)
{
  my $val = 'LAST';
  my @select = ( 'v_hides', undef );

  if(exists $arg{id} && defined $arg{id}) {
    if($arg{id}) {
      $val = $arg{id};
      push(@select, { hides_i => $val });
    } else {
      push(@select, undef, { -desc => 'hides_i'});
    }
  } elsif($arg{cacheid}) {
    $val = $arg{cacheid};
    push(@select, { cacheid => $val });
  }

  my $re = $self->sqlite->db->select(@select);
  my $entry = $re->hash;
  if($entry) {
    $self->set_from_db_row(%$entry)
  } else {
    die "Hide $val not found";
  }
  $re->finish;

  return $self;
}

1;
