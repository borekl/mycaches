package MyCaches::Model::Hides;

use Mojo::Base -base, -signatures;
use Time::Moment;
use Try::Tiny;

has 'db';


#------------------------------------------------------------------------------
# Function to calculate 'age' and 'held' fields. Accepts a Mojo::Collection
# of entries.
#------------------------------------------------------------------------------

sub fix_entries($self, $hides)
{
  my $now = Time::Moment->now;
  my $tz = $now->strftime('%:z');

  return $hides->map(sub {
    my %h = %$_;

    # ignore unpublished hides
    next if !$h{published};
    # compute hide's days since last find, or if not found, from publication
    my $last_found = Time::Moment->from_string($h{found} . "T00:00$tz")
      if $h{found};
    my $published = Time::Moment->from_string($h{published} . "T00:00$tz")
      if $h{published};
    my $timeref = $last_found // $published;
    $h{age} = $timeref->at_midnight->delta_days($now->at_midnight);

    return \%h;
  });
}

#------------------------------------------------------------------------------
# Retrieve and return list of finds.
#------------------------------------------------------------------------------

sub list($self)
{
  $self->fix_entries(
    $self->db->query(q{SELECT * FROM hides})->hashes
  );
}


1;
