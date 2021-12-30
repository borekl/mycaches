package MyCaches::Model::Log;

use Moo;
with 'MyCaches::Roles::LocalTZ';
use experimental 'signatures';
use MyCaches::Types::Date;

# ref to db connection
has 'db' => ( is => 'ro' );
# row id
has 'id' => ( is => 'rw' );
# cache id (GC code)
has 'cacheid' => ( is => 'ro' );
# sequence number
has 'seq' => ( is => 'rw' );
# date
has 'date' => (
  is => 'ro',
  coerce => sub ($v) { MyCaches::Types::Date::ingest($v) }
);
# player name
has 'player' => ( is => 'ro' );
# log type
has 'logtype' => ( is => 'ro' );
# log UUID
has 'logid' => ( is => 'ro' );

around BUILDARGS => sub ($orig, $class, %arg) {
  # create from database entry
  if(exists $arg{entry}) {
    $arg{id} = $arg{entry}{logs_i};
    $arg{seq} = $arg{entry}{seq};
    $arg{date} = $arg{entry}{date};
    $arg{cacheid} = $arg{entry}{cacheid};
    $arg{player} = $arg{entry}{player};
    $arg{logtype} = $arg{entry}{logtype};
    $arg{logid} = $arg{entry}{logid};
    delete $arg{entry};
  }
  # finish
  return $class->$orig(%arg);
};

#------------------------------------------------------------------------------
# Return instance data as hash
sub to_hash ($self)
{
  my %data;

  $data{logs_i} = $self->id if defined $self->id;
  $data{seq} = $self->seq;
  $data{date} = $self->date->strftime('%F');
  $data{cacheid} = $self->cacheid;
  $data{player} = $self->player;
  $data{logtype} = $self->logtype;
  $data{logid} = $self->logid;

  return \%data;
}

#------------------------------------------------------------------------------
# Find the next sequence number for a log entry for a given date
sub get_next_seq ($self)
{
  my $date = $self->date->strftime('%F');
  my $re = $self->db->select(
    'logs', 'seq', { date => $date }, { -desc => 'seq' }
  );
  my $row = $re->hash;
  $re->finish;

  return $row->{seq} + 1;
}

#------------------------------------------------------------------------------
sub add_log($self)
{
  my $db = $self->db;
  my $tx = $db->begin;
    $self->seq($self->get_next_seq) unless $self->seq;
    my $entry = $self->to_hash;
    $db->insert('logs', $entry);
  $tx->commit;
  return $self;
}

#------------------------------------------------------------------------------
sub update_log($self)
{
  $self->db->update('logs', $self->to_hash, { logs_i => $self->id });
}

#------------------------------------------------------------------------------
sub delete_log($self)
{
  $self->db->delete('logs', { logs_i => $self->id });
  return $self;
}

1;
