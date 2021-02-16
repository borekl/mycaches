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
    $arg{name} = $e->{name};
    $arg{terrain} = $e->{terrain};
    $arg{difficulty} = $e->{difficulty};
    $arg{gallery} = $e->{gallery};
    $arg{archived} = $e->{archived};
  }

  #--- finish

  $self->SUPER::new(%arg);
}

#------------------------------------------------------------------------------
# Return data as hash
#------------------------------------------------------------------------------

sub to_hash($self)
{{
  id => $self->id,
  cacheid => $self->cacheid,
  name => $self->name,
  difficulty => $self->difficulty,
  terrain => $self->terrain,
  ctype => $self->ctype,
  gallery => $self->gallery,
  archived => $self->archived,
  now => $self->now,
  tz => $self->tz,
}}

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

1;
