package MyCaches::Model::Loglist;

use Moo;
use strict;
use warnings;
use experimental 'signatures';

use List::Util qw(max);

# ref to db connection
has 'sqlite' => (
  is => 'ro',
  isa => sub { die 'Need sqlite' unless $_[0]->isa('Mojo::SQLite')}
);
# the cache this list is associated with
has 'cacheid' => ( is => 'ro', required => 1, coerce => sub ($v) { uc $v } );
# list of log (hashref, keys are logs_i field)
has 'logs' => ( is => 'lazy' );

#-------------------------------------------------------------------------------
# load all logs
sub _build_logs ($self)
{
  my $db = $self->sqlite->db;
  my %logs;

  my $re = $db->select(
    'logs',                         # table name
    undef,                          # fields (*)
    { cacheid => $self->cacheid },  # WHERE clause
    { -asc => [ 'date', 'seq' ] }   # ORDER BY clause
  );

  while(my $row = $re->hash) { $logs{$row->{logs_i}} = $row }

  $re->finish;
  return \%logs;
}

#-------------------------------------------------------------------------------
# get the highest row id or 0 in case of empty log list
sub get_last_id ($self)
{
  my $db = $self->sqlite->db;
  my $re = $db->select('logs', 'logs_i', undef, { -desc => 'logs_i' });
  my $row = $re->hash;
  $re->finish;

  return $row->{logs_i} // 0;
}

#-------------------------------------------------------------------------------
# get the next sequence number for given date
sub get_next_seq ($self, $date)
{
  my $logs = $self->logs;
  my $seq = max map {
    $logs->{$_}{seq}
  } grep {
    $logs->{$_}{date} eq $date
  } keys %$logs;
  return defined $seq ? $seq + 1 : 0;
}

#-------------------------------------------------------------------------------
# Add new entry to log, both in backend database and in the instance
sub add ($self, %args)
{
  my $db = $self->sqlite->db;

  # ensure the cache id is correct
  die 'Invalid cacheid' unless $args{cacheid} eq $self->cacheid;

  # transact the insert
  my $tx = $db->begin;
    $args{logs_i} = $self->get_last_id + 1;
    $args{seq} = $self->get_next_seq($args{date});
    $db->insert('logs', \%args);
  $tx->commit;

  # finish
  $self->logs->{$args{logs_i}} = \%args;
  return \%args;
}

#-------------------------------------------------------------------------------
# Delete a log by its row id
sub delete ($self, $id)
{
  my $db = $self->sqlite->db;

  my $r = $self->sqlite->db->delete(
    'logs', { logs_i => $id, cacheid => $self->cacheid }
  );
  die "Log $id not found" unless $r->rows;
  delete $self->logs->{$id};
  return $self;
}

#-------------------------------------------------------------------------------
# Update a log entry
sub update ($self, $id, %args)
{
  my $db = $self->sqlite->db;
  delete $args{logs_i} if exists $args{logs_i};
  delete $args{cacheid} if exists $args{cacheid};

  my $r = $self->sqlite->db->update(
    'logs', \%args, { logs_i => $id }
  );
  die "Log $id not found" unless $r->rows;
  $self->logs->{$id} = { $self->logs->{$id}->%*, %args };
  return $self;
}

#-------------------------------------------------------------------------------
# Swap two entries with the same date.
sub swap ($self, $id1, $id2)
{
  my $db = $self->sqlite->db;

  # enforce equal dates on entries
  die 'Invalid swap operation'
  if $self->logs->{$id1}{date} ne $self->logs->{$id2}{date};

  # prepare data
  my $seq1 = $self->logs->{$id1}{seq};
  my $seq2 = $self->logs->{$id2}{seq};

  # transact the update
  my $tx = $db->begin;
    my $r;
    $r = $db->update('logs', { seq => $seq2 }, { logs_i => $id1 });
    die 'Entry swap failed' unless $r->rows;
    $r = $db->update('logs', { seq => $seq1 }, { logs_i => $id2 });
    die 'Entry swap failed' unless $r->rows;
    $self->logs->{$id1}{seq} = $seq2;
    $self->logs->{$id2}{seq} = $seq1;
  $tx->commit;
  return $self;
}

1;
