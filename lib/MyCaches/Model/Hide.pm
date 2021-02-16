package MyCaches::Model::Hide;

use Mojo::Base 'MyCaches::Model::Cache', -signatures;


#------------------------------------------------------------------------------
# ATTRIBUTES
#------------------------------------------------------------------------------

has 'published';     # publication date
has 'finds' => 0;    # number of finds
has 'found';         # last find date

# cache status (0-unspecified, 1-active, 2-disabled, 3-in development,
# 4-waiting to be placed, 5-waiting for publication)
has 'status' => 0;

# publication date as Time::Moment object
has 'published_tm' => sub {
  my $self = shift;
  $self->published ? $self->tm_from_date($self->published) : undef;
};

# last find date as Time::Moment object
has 'found_tm' => sub {
  my $self = shift;
  $self->found ? $self->tm_from_date($self->found) : undef;
};

# age, or days since last find
has 'age' => sub {
  my $self = shift;
  my $ref_date = $self->published;
  $ref_date = $self->found_tm if $self->found_tm;
  if($ref_date) {
    return $ref_date->at_midnight->delta_days($self->now->at_midnight);
  } else {
    return undef;
  }
};

#------------------------------------------------------------------------------
# CONSTRUCTOR // we allow for alternate ways of initializing the instance
#------------------------------------------------------------------------------

sub new
{
  my ($self, %arg) = @_;

  #--- loading a database entry

  if($arg{id}) {
    my $db = $arg{db};
    my $re = $db->select('hides', undef, { hides_i => $arg{id}});
    my $entry = $re->hash;
    if($entry) {
      delete $arg{id};
      $arg{entry} = $entry;
    }
    $re->finish;
  }

  #--- initialization with a database entry

  if(exists $arg{entry}) {
    my $e = $arg{entry};
    $arg{hides_i} = $e->{hides_i};
    $arg{published} = $e->{published};
    $arg{finds} = $e->{finds};
    $arg{found} = $e->{found};
    $arg{status} = $e->{status};
  }

  #--- finish

  $self->SUPER::new(%arg);
}

#------------------------------------------------------------------------------
# Return data as hash
#------------------------------------------------------------------------------

sub to_hash($self)
{
  my $data = $self->SUPER::to_hash;

  $data->{hides_i} = $self->{hides_i};
  $data->{published} = $self->published;
  $data->{finds} = $self->finds;
  $data->{found} = $self->found;
  $data->{published_tm} = $self->published_tm;
  $data->{found_tm} = $self->found_tm;
  $data->{age} = $self->age;

  return $data;
}

#------------------------------------------------------------------------------

1;
