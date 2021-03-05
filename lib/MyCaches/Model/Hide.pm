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
  my (@select, $val);

  #--- loading an entry from database -----------------------------------------
  # keys load.id or load.cacheid will make the constructor to attempt loading
  # single entry and use its contents to initialize the instance; when load.id
  # is defined but false, the highest rowid entry is loaded

  if(exists $arg{load}) {

    if(exists $arg{load}{id}) {
      if($arg{load}{id} > 0) {
        @select = ( 'hides', undef, { hides_i => $arg{load}{id} } );
      } else {
        @select = ( 'hides', undef, undef, { -desc => 'hides_i' } );
      }
      $val = $arg{load}{id};
    }

    elsif(exists $arg{load}{cacheid}) {
      @select = ( 'hides', undef, { cacheid => $arg{load}{cacheid} } );
      $val = $arg{load}{cacheid};
    }

    delete $arg{load};

    my $re = $arg{db}->select(@select);
    my $entry = $re->hash;
    if($entry) {
      $arg{entry} = $entry;
    } else {
      die "Hide $val not found";
    }
    $re->finish;

  }

  #--- initialization with a database entry

  if(exists $arg{entry}) {
    my $e = $arg{entry};
    $arg{id} = $e->{hides_i};
    $arg{published} = $e->{published};
    $arg{finds} = $e->{finds};
    $arg{found} = $e->{found};
    $arg{status} = $e->{status};
  }

  #--- map rowid

  else {
    $arg{id} = $arg{hides_i} if exists $arg{hides_i}
  }

  #--- finish

  $self->SUPER::new(%arg);
}

#------------------------------------------------------------------------------
# Return data as hash
#------------------------------------------------------------------------------

sub to_hash($self, %arg)
{
  my $data = $self->SUPER::to_hash(%arg);

  $data->{hides_i} = $self->id;
  $data->{published} = $self->published;
  $data->{finds} = $self->finds;
  $data->{found} = $self->found;
  $data->{age} = $self->age unless $arg{db};

  return $data;
}

#------------------------------------------------------------------------------
# Return new row id for new entry
#------------------------------------------------------------------------------

sub get_new_id($self)
{
  $self->id($self->get_last_id('hides') + 1);
  return $self;
}

#------------------------------------------------------------------------------
# Create new entry in the database
#------------------------------------------------------------------------------

sub create($self)
{
  my $db = $self->db;
  my $entry = $self->get_new_id->to_hash(db => 1);
  $db->insert('hides', $entry);
  return $self;
}

#------------------------------------------------------------------------------
# Update existing entry in the database
#------------------------------------------------------------------------------

sub update($self)
{
  $self->db->update(
    'hides',
    $self->to_hash(db => 1),
    { hides_i => $self->id }
  );
  return $self;
}

#------------------------------------------------------------------------------
# Delete existing entry in the database
#------------------------------------------------------------------------------

sub delete($self)
{
  $self->db->delete('hides', { hides_i => $self->id });
  return $self;
}

#------------------------------------------------------------------------------

1;
