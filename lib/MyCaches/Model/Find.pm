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
  $self->calc_years_days($self->prev_tm, $self->found_tm);
};

# held, or how many days I was the last finder
has 'held' => sub {
  my $self = shift;
  $self->calc_years_days($self->found_tm, $self->next_tm // $self->now);
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
        @select = ( 'finds', undef, { finds_i => $arg{load}{id} } );
      } else {
        @select = ( 'finds', undef, undef, { -desc => 'finds_i' } );
      }
      $val = $arg{load}{id};
    }

    elsif(exists $arg{load}{cacheid}) {
      @select = ( 'finds', undef, { cacheid => $arg{load}{cacheid} } );
      $val = $arg{load}{cacheid};
    }

    delete $arg{load};

    my $re = $arg{db}->select(@select);
    my $entry = $re->hash;
    if($entry) {
      $arg{entry} = $entry;
    } else {
      die "Find $val not found";
    }
    $re->finish;
  }

  #--- initialization with a database entry
  # if 'entry' hashref is passed as argument, use it to initialize the instance
  # the contents is expected to be a verbatim database row

  if(exists $arg{entry}) {
    my $e = $arg{entry};
    $arg{id} = $e->{finds_i};
    $arg{prev} = $e->{prev};
    $arg{found} = $e->{found};
    $arg{next} = $e->{next};
    $arg{favorite} = $e->{favorite};
    $arg{xtf} = $e->{xtf};
    $arg{logid} = $e->{logid};
  }

  #--- map rowid

  else {
    $arg{id} = $arg{finds_i} if exists $arg{finds_i}
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

  $data->{finds_i} = $self->id;
  $data->{prev} = $self->prev;
  $data->{found} = $self->found;
  $data->{next} = $self->next;
  $data->{favorite} = $self->favorite;
  $data->{xtf} = $self->xtf;
  $data->{logid} = $self->logid;
  # following are computed fields, not relevant for instances used for saving
  # to database
  if(!$arg{db}) {
    $data->{age} = $self->age;
    $data->{held} = $self->held;
  }

  return $data;
}

#------------------------------------------------------------------------------
# Return new row id for new entry
#------------------------------------------------------------------------------

sub get_new_id($self)
{
  $self->id($self->get_last_id('finds') + 1);
  return $self;
}

#------------------------------------------------------------------------------
# Create new entry in the database
#------------------------------------------------------------------------------

sub create($self)
{
  my $db = $self->db;
  my $entry = $self->get_new_id->to_hash(db => 1);
  $db->insert('finds', $entry);
  return $self;
}

#------------------------------------------------------------------------------
# Update existing entry in the database
#------------------------------------------------------------------------------

sub update($self)
{
  $self->db->update(
    'finds',
    $self->to_hash(db => 1),
    { finds_i => $self->id }
  );
  return $self;
}

#------------------------------------------------------------------------------
# Delete existing entry in the database
#------------------------------------------------------------------------------

sub delete($self)
{
  $self->db->delete('finds', { finds_i => $self->id });
  return $self;
}

#------------------------------------------------------------------------------

1;
