package MyCaches::Model::Find;

# class representing single find, based off Cache class

use Moo;
extends 'MyCaches::Model::Cache';
use experimental 'signatures';
use MyCaches::Types::Date;
use MyCaches::Model::Const;

# previous find date
has 'prev' => (
  is => 'ro',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# my find date
has 'found' => (
  is => 'ro',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# next find date
has 'next' => (
  is => 'ro',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# cache favorited by me flag
has 'favorite' => ( is => 'ro', default => 0 );
# ftf/stf/ttf flag
has 'xtf' => ( is => 'ro', default => 0 );
# log id string ('LUID')
has 'logid' => ( is => 'ro' );
# age, or how many days since last find when I found the cache
has 'age' => (
  is => 'lazy',
  default => sub ($self) {
    $self->calc_years_days($self->prev, $self->found);
  }
);
# held, or how many days I was the last finder
has 'held' => (
  is => 'lazy',
  default => sub ($self) {
    $self->calc_years_days($self->found, $self->next // $self->now);
  }
);

#-------------------------------------------------------------------------------
# code implementing alternate way of initializing the instance from loaded
# database entry stored in 'entry' key
around BUILDARGS => sub ($orig, $class, %arg)
{
  my (@select, $val);

  # loading an entry from database // keys load.id or load.cacheid will make the
  # constructor to attempt loading single entry and use its contents to
  # initialize the instance; when load.id is defined but false, the highest
  # rowid entry is loaded
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

    my $re = $arg{sqlite}->db->select(@select);
    my $entry = $re->hash;
    if($entry) {
      $arg{entry} = $entry;
    } else {
      die "Find $val not found";
    }
    $re->finish;
  }

  # initialization with a database entry // if 'entry' hashref is passed as
  # argument, use it to initialize the instance the contents is expected to be a
  # verbatim database row
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

  # map rowid
  else {
    $arg{id} = $arg{finds_i} if exists $arg{finds_i}
  }

  # archived flag mapping; if we receve archived = 1 from the frontend, we map
  # this to status = 6
  $arg{status} = ST_ARCHIVED if $arg{archived};
  delete $arg{archived} if exists $arg{archived};

  # finish
  return $class->$orig(%arg);
};

#-------------------------------------------------------------------------------
# return instance data as a hash, suitable for sending to database
sub hash_for_db ($self)
{
  my $data = $self->SUPER::hash_for_db;

  $data->{finds_i} = $self->id;
  $data->{prev} = $self->prev ? $self->prev->strftime('%F') : undef;
  $data->{found} = $self->found ? $self->found->strftime('%F') : undef;
  $data->{next} = $self->next ? $self->next->strftime('%F') : undef;
  $data->{favorite} = $self->favorite;
  $data->{xtf} = $self->xtf;
  $data->{logid} = $self->logid;

  return $data;
}

#-------------------------------------------------------------------------------
# return instance data as a hash, transformed and filled in with fields suitable
# for client
sub hash_for_client ($self)
{
  my $data = $self->SUPER::hash_for_client;
  $data->{age} = $self->age;
  $data->{held} = $self->held;
  return $data;
}

1;
