package MyCaches::Model::Cache;

use Moo;
use experimental 'signatures';
use Time::Moment;

#------------------------------------------------------------------------------
# ATTRIBUTES
#------------------------------------------------------------------------------

# ref to db connection
has 'db' => ( is => 'ro' );
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
# cache archived flag
has 'archived' => ( is => 'ro', default => 0 );
# loading time
has 'now' => (
  is => 'ro',
  default => sub { Time::Moment->now->at_midnight }
);
# local timezone
has 'tz' => (
  is => 'lazy',
  default => sub ($self) { $self->now->strftime('%:z') }
);

#------------------------------------------------------------------------------
# We allow for alternate ways of initializing the instance
#------------------------------------------------------------------------------

around BUILDARGS => sub ($orig, $class, %arg) {

  #--- initialization with a database entry

  if(exists $arg{entry}) {
    my $e = $arg{entry};
    $arg{cacheid} = $e->{cacheid};
    $arg{ctype} = $e->{ctype};
    $arg{name} = $e->{name};
    $arg{terrain} = $e->{terrain} / 2;
    $arg{difficulty} = $e->{difficulty} / 2;
    $arg{gallery} = $e->{gallery};
    $arg{archived} = $e->{archived};
  }

  #--- values that are equal to empty strings are converted to undef

  foreach my $k (keys %arg) { $arg{$k} = undef if $arg{$k} && $arg{$k} eq '' }

  #--- finish

  return $class->$orig(%arg);
};

#------------------------------------------------------------------------------
# Return data as hash
#------------------------------------------------------------------------------

sub to_hash($self, %arg)
{
  my %re = (
    cacheid => $self->cacheid,
    name => $self->name,
    difficulty => $self->difficulty,
    terrain => $self->terrain,
    ctype => $self->ctype,
    gallery => $self->gallery,
    archived => $self->archived,
  );

  $re{tz} = $self->tz unless $arg{db};
  $re{difficulty} *= 2 if $arg{db};
  $re{terrain} *= 2 if $arg{db};

  return \%re;
}

#------------------------------------------------------------------------------
# Receive date in ISO format and return Time::Moment object
#------------------------------------------------------------------------------

sub tm_from_date($self, $date)
{
  my $now = Time::Moment->now;
  my $tz = $now->strftime('%:z');
  return Time::Moment->from_string($date . "T00:00$tz");
}

#------------------------------------------------------------------------------
# Auxiliary function to get last rowid from a table. This is needed when adding
# a new entry. We are not using sequences since our rowids actually have some
# semantics to them. FIXME
#------------------------------------------------------------------------------

sub get_last_id($self, $table)
{
  my $db = $self->db;
  my $rowid = "${table}_i";
  my $re = $db->select($table, $rowid, undef, { -desc => $rowid });
  my $row = $re->hash;
  $re->finish;

  return $row->{$rowid} // 0;
}

#------------------------------------------------------------------------------
# Calculate time difference between two points of time (supplied as
# Time::Moment instances) in years and days.
#------------------------------------------------------------------------------

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

1;
