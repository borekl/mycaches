package MyCaches::Model::Finds;

use Mojo::Base -base, -signatures;
use Time::Moment;
use Try::Tiny;

has 'db';


#------------------------------------------------------------------------------
# Function to calculate 'age' and 'held' fields. Accepts a Mojo::Collection
# of entries.
#------------------------------------------------------------------------------

sub fix_entries($self, $finds)
{
  my $now = Time::Moment->now;
  my $tz = $now->strftime('%:z');

  return $finds->map(sub {
    my %h = %$_;

    try {
      # calculate 'age', ie. numer of days since previous find
      my $previous_find
        = Time::Moment->from_string($h{prev} . "T00:00$tz")
        if $h{prev};
      my $found = Time::Moment->from_string($h{found} . "T00:00$tz");
      $h{age} = $previous_find->delta_days($found) if $h{prev};

      # calculate 'held', ie. number of days when I was the last finder
      my $next_find
        = $h{next}
        ? Time::Moment->from_string($h{next} . "T00:00$tz")
        : $now->at_midnight;

      $h{held} = $found->delta_days($next_find);
    };

    return \%h;
  });
}

#------------------------------------------------------------------------------
# Retrieve and return list of finds.
#------------------------------------------------------------------------------

sub list($self)
{
  $self->fix_entries(
    $self->db->query(q{SELECT * FROM finds})->hashes
  );
}


1;
