package MyCaches::Model::Hide;

# class representing single find, based off Cache class

use Moo;
extends 'MyCaches::Model::Cache';
use experimental 'signatures';
use MyCaches::Types::Date;
use POSIX qw(strftime);

# publication date
has 'published' => (
  is => 'ro',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# number of finds / note that this is not a field in the backend 'hides' table
# but an aggregate number of 'found it' logs in the 'logs' table
has 'finds' => (
  is => 'ro', default => 0,
  coerce => sub ($v) { int($v) },
);
# last find date
has 'found' => (
  is => 'ro',
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

1;
