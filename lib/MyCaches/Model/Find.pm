package MyCaches::Model::Find;

use Mojo::Base 'MyCaches::Model::Cache', -signatures;


#------------------------------------------------------------------------------
# ATTRIBUTES
#------------------------------------------------------------------------------

has 'prev';                 # previous find date
has 'found';                # my find date
has 'next';                 # next find date
has 'favorite' => 0;        # cache favorited by me flag
has 'xtf' => 0;             # ftf/stf/ttf flag
has 'logid';                # log id string ('LUID')

# previous find date as Time::Moment object
has 'prev_tm' => sub {
  my $self = shift;
  $self->prev ? $self->tm_from_date($self->prev) : undef;
};

# my find date as Time::Moment object
has 'found_tm' => sub {
  my $self = shift;
  $self->found ? $self->tm_from_date($self->found) : undef;
};

# next find date as Time::Moment object
has 'next_tm' => sub {
  my $self = shift;
  $self->next ? $self->tm_from_date($self->next) : undef;
};

# age, or how many days since last find when I found the cache
has 'age' => sub {
  my $self = shift;
  if($self->prev && $self->found) {
    return $self->prev_tm->delta_days($self->found_tm);
  } else {
    return undef;
  }
};

# held, or how many days I was the last finder
has 'held' => sub {
  my $self = shift;
  if($self->found && $self->next) {
    return $self->found_tm->delta_days($self->next_tm);
  } else {
    return $self->found_tm->delta_days($self->now);
  }
};

#------------------------------------------------------------------------------
# CONSTRUCTOR // we allow for alternate ways of initializing the instance
#------------------------------------------------------------------------------

sub new
{
  my ($self, %arg) = @_;

  #--- initialization with a database entry

  if(exists $arg{entry}) {
    my $e = $arg{entry};
    $arg{prev} = $e->{prev};
    $arg{found} = $e->{found};
    $arg{next} = $e->{next};
    $arg{favorite} = $e->{favorite};
    $arg{xtf} = $e->{xtf};
    $arg{logid} = $e->{logid};
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

  $data->{finds_i} = $self->{finds_i};
  $data->{prev} = $self->prev;
  $data->{found} = $self->found;
  $data->{next} = $self->next;
  $data->{favorite} = $self->favorite;
  $data->{xtf} = $self->xtf;
  $data->{logid} = $self->logid;
  $data->{prev_tm} = $self->prev_tm;
  $data->{found_tm} = $self->found_tm;
  $data->{next_tm} = $self->next_tm;
  $data->{age} = $self->age;
  $data->{held} = $self->held;

  return $data;
}

#------------------------------------------------------------------------------

1;
