package MyCaches::Model::Cache;

use Mojo::Base -base, -signatures;
use Time::Moment;

#------------------------------------------------------------------------------
# ATTRIBUTES
#------------------------------------------------------------------------------

has 'db';                  # ref to db connection

# common cache attributes (both hides and finds have them)
has 'id';                  # row id
has 'cacheid';             # cache id
has 'name';                # cache name
has 'difficulty' => 1;     # cache difficulty (1-5 in steps of 0.5)
has 'terrain' => 1;        # cache terrain (1-5 in steps of 0.5)
has 'ctype' => 2;          # cache type (as specified in icon SVG)
has 'gallery' => 0;        # gallery available flag
has 'archived' => 0;       # cache archived flag

# loading time / timezone
has 'now' => sub { Time::Moment->now };
has 'tz' => sub { $_[0]->now->strftime('%:z') };


#------------------------------------------------------------------------------
# CONSTRUCTOR // we allow for alternate ways of initializing the instance
#------------------------------------------------------------------------------

sub new
{
  my ($self, %arg) = @_;

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

  $self->SUPER::new(%arg);
}

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

  return $row->{$rowid};
}

#------------------------------------------------------------------------------

1;
