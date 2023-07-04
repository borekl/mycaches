package MyCaches::Model::Find;

# class representing single find, based off Cache class

use Moo;
extends 'MyCaches::Model::Cache';
use experimental 'signatures';
use MyCaches::Types::Date;
use MyCaches::Model::Const;

# previous find date
has 'prev' => (
  is => 'rwp',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# my find date
has 'found' => (
  is => 'rwp',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# next find date
has 'next' => (
  is => 'rwp',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# cache favorited by me flag
has 'favorite' => ( is => 'rwp', default => 0 );
# ftf/stf/ttf flag
has 'xtf' => ( is => 'rwp', default => 0 );
# log id string ('LUID')
has 'logid' => ( is => 'rwp' );
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

#-------------------------------------------------------------------------------
# set instance attributes from a database row
sub set_from_db_row ($self, %e)
{
  $self->SUPER::set_from_db_row(%e);
  $self->_set_id($e{finds_i});
  $self->_set_prev($e{prev});
  $self->_set_found($e{found});
  $self->_set_next($e{next});
  $self->_set_favorite($e{favorite});
  $self->_set_xtf($e{xtf});
  $self->_set_logid($e{logid});
  return $self;
}

#-------------------------------------------------------------------------------
# load single entry specified either by rowid ('id') or cacheid; defined but
# false rowid (ie. id == 0) will load the highest rowid entry
sub load ($self, %arg)
{
  my $val = 'LAST';
  my @select = ( 'finds', undef );

  if(exists $arg{id} && defined $arg{id}) {
    if($arg{id}) {
      $val = $arg{id};
      push(@select, { finds_i => $val });
    } else {
      push(@select, undef, { -desc => 'finds_i'});
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
    die "Find $val not found";
  }
  $re->finish;

  return $self;
}

1;
