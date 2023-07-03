package MyCaches::Model::Cache;

# base class for Finds and Hides, contains common attributes and methods; this
# should never be used directly

use Moo;
with 'MyCaches::Roles::LocalTZ';
use experimental 'signatures';
use Time::Moment;
use MyCaches::Model::Const;

# ref to db connection
has 'sqlite' => (
  is => 'ro',
  isa => sub { die 'Need sqlite' unless $_[0]->isa('Mojo::SQLite')}
);
# row id
has 'id' => ( is => 'rw' );
# cache id (GC code)
has 'cacheid' => ( is => 'ro' );
# cache name
has 'name'  => ( is => 'ro' );
# cache difficulty (1-5 in steps of 0.5)
has 'difficulty' => ( is => 'ro', default => 1 );
# cache terrain (1-5 in steps of 0.5)
has 'terrain' => ( is => 'ro', default => 1 );
# cache type (as specified in icon SVG)
has 'ctype' => ( is => 'ro', default => 2 );
# gallery available flag
has 'gallery' => ( is => 'ro', default => 0 );
# cache status
has 'status' => (
  is => 'ro',
  default => ST_UNDEF,
  coerce => sub { $_[0] // ST_UNDEF }
);

#-------------------------------------------------------------------------------
# code implementing alternate way of initializing the instance from loaded
# database entry stored in 'entry' key
around BUILDARGS => sub ($orig, $class, %arg)
{
  # initialization with a database entry
  if(exists $arg{entry}) {
    my $e = $arg{entry};
    $arg{cacheid} = $e->{cacheid};
    $arg{ctype} = $e->{ctype};
    $arg{name} = $e->{name};
    $arg{terrain} = $e->{terrain} / 2;
    $arg{difficulty} = $e->{difficulty} / 2;
    $arg{gallery} = $e->{gallery};
    $arg{status} = $e->{status};
  }

  # values that are equal to empty strings are converted to undef
  foreach my $v (values %arg) {
    undef $v unless length $v;
  }

  # finish
  return $class->$orig(%arg);
};

#-------------------------------------------------------------------------------
# return instance data as a hash, suitable for sending to database
sub hash_for_db ($self) {{
  cacheid => $self->cacheid,
  name => $self->name,
  difficulty => $self->difficulty * 2,
  terrain => $self->terrain * 2,
  ctype => $self->ctype,
  gallery => $self->gallery,
  status => $self->status,
}}

#-------------------------------------------------------------------------------
# return instance data as a hash, transformed and filled in with fields suitable
# for client
sub hash_for_client ($self)
{
  my $re = $self->hash_for_db;
  $re->{id} = $self->id;
  $re->{tz} = $self->tz;
  $re->{difficulty} = $self->difficulty;
  $re->{terrain} = $self->terrain;
  return $re;
}

#-------------------------------------------------------------------------------
# Auxiliary function to get last rowid from a table. This is needed when adding
# a new entry. We are not using sequences since our rowids actually have some
# semantics to them. FIXME: that might not be a good idea
sub get_last_id($self)
{
  my $table = $self->_db_table;
  my $db = $self->sqlite->db;
  my $rowid = "${table}_i";
  my $re = $db->select($table, $rowid, undef, { -desc => $rowid });
  my $row = $re->hash;
  $re->finish;

  return $row->{$rowid} // 0;
}

#-------------------------------------------------------------------------------
# set new id for this instance
sub get_new_id($self)
{
  $self->id($self->get_last_id + 1);
  return $self;
}

#-------------------------------------------------------------------------------
# calculate time difference between two points of time (supplied as Time::Moment
# instances) in years and days.
sub calc_years_days($self, $tm1, $tm2 )
{
  my %re = ( years => 0, days => 0, rdays => 0 );

  return undef if !$tm1 || !$tm2;

  $re{days} = $tm1->delta_days($tm2);

  if($re{years} = $tm1->delta_years($tm2)) {
    $tm1 = $tm1->plus_years($re{years});
  }
  $re{rdays} = $tm1->delta_days($tm2);

  return \%re;
}

#------------------------------------------------------------------------------
# return backend database table for the instance
sub _db_table($self) {
  if($self->isa('MyCaches::Model::Find')) {
    return 'finds';
  } elsif($self->isa('MyCaches::Model::Hide')) {
    return 'hides';
  } else {
    die "Unrecognized cache instance type '$self'";
  }
}

#------------------------------------------------------------------------------
# create new entry in the database
sub create($self)
{
  my $db = $self->sqlite->db;
  my $entry = $self->get_new_id->hash_for_db;
  $db->insert($self->_db_table, $entry);
  return $self;
}

#------------------------------------------------------------------------------
# update existing entry in the database
sub update($self)
{
  my $table = $self->_db_table;
  my $label = ucfirst(substr($table, 0, length($table) - 1));
  my $id = $self->id;
  my $r = $self->sqlite->db->update(
    $table,
    $self->hash_for_db,
    { "${table}_i" => $id }
  );
  die "$label $id not found" unless $r->rows;
  return $self;
}

#------------------------------------------------------------------------------
# delete existing entry in the database
sub delete($self)
{
  my $table = $self->_db_table;
  my $label = ucfirst(substr($table, 0, length($table) - 1));
  my $id = $self->id;
  my $r = $self->sqlite->db->delete(
    $table, { "${table}_i" => $id }
  );
  die "$label $id not found" unless $r->rows;
  return $self;
}

1;
