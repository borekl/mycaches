package MyCaches::Model::Cache;

# base class for Finds and Hides, contains common attributes and methods; this
# should never be used directly

use Moo;
with 'MyCaches::Roles::LocalTZ';
use experimental 'signatures';
use Time::Moment;
use MyCaches::Model::Const;
use MyCaches::Misc qw(empty_strings_to_undefs);

# ref to db connection
has 'sqlite' => (
  is => 'ro',
  isa => sub { die 'Need sqlite' unless $_[0]->isa('Mojo::SQLite')}
);
# row id
has 'id' => ( is => 'rwp' );
# cache id (GC code)
has 'cacheid' => ( is => 'rwp' );
# cache name
has 'name'  => ( is => 'rwp' );
# cache difficulty (1-5 in steps of 0.5)
has 'difficulty' => ( is => 'rwp', default => 1 );
# cache terrain (1-5 in steps of 0.5)
has 'terrain' => ( is => 'rwp', default => 1 );
# cache type (as specified in icon SVG)
has 'ctype' => ( is => 'rwp', default => 2 );
# gallery available flag
has 'gallery' => ( is => 'rwp', default => 0 );
# cache status
has 'status' => (
  is => 'rwp',
  default => ST_UNDEF,
  coerce => sub { $_[0] // ST_UNDEF }
);

# convert empty strings to undefs when creating new instance
around BUILDARGS => sub ($orig, $class, %arg)
{
  empty_strings_to_undefs(\%arg);
  return $class->$orig(%arg);
};

#-------------------------------------------------------------------------------
# set instance attributes from a database row
sub set_from_db_row ($self, %e)
{
  empty_strings_to_undefs(\%e);
  $self->_set_cacheid($e{cacheid});
  $self->_set_ctype($e{ctype});
  $self->_set_name($e{name});
  $self->_set_terrain($e{terrain} / 2);
  $self->_set_difficulty($e{difficulty} / 2);
  $self->_set_gallery($e{gallery});
  $self->_set_status($e{status});
  return $self;
}

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
  $self->_set_id($self->get_last_id + 1);
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
