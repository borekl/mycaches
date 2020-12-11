#!/usr/bin/perl

use Mojolicious::Lite -signatures;
use Mojo::SQLite;
use Time::Moment;
use Try::Tiny;

#==============================================================================

helper sqlite => sub {
  state $sql = Mojo::SQLite->new('mycaches.sqlite')
};


#==============================================================================

#------------------------------------------------------------------------------
# The function to calculate 'age' and 'held' fields from entries retrieved
# from the database.
#------------------------------------------------------------------------------

sub caches($caches)
{
  my $now = Time::Moment->now;
  my $tz = $now->strftime('%:z');

  return $caches->map(sub {
    my %h = %$_;

    #--- hides

    if(exists $h{hides_i}) {
      # ignore unpublished hides
      next if !$h{published};
      # compute hide's days since last find, or if not found, from publication
      my $last_found = Time::Moment->from_string($h{found} . "T00:00$tz")
        if $h{found};
      my $published = Time::Moment->from_string($h{published} . "T00:00$tz")
        if $h{published};
      my $timeref = $last_found // $published;
      $h{age} = $timeref->at_midnight->delta_days($now->at_midnight);
    }

    #--- finds

    elsif(exists $h{finds_i}) {
      # calculate 'age', ie. numer of days since previous find
      try {
        my $previous_find = Time::Moment->from_string($h{prev} . "T00:00$tz");
        my $found = Time::Moment->from_string($h{found} . "T00:00$tz");
        $h{age} = $previous_find->delta_days($found);

      # calculate 'held', ie. number of days when I was the last finder
        my $next_find
          = $h{next}
          ? Time::Moment->from_string($h{next} . "T00:00$tz")
          : $now->at_midnight;

        $h{held} = $found->delta_days($next_find);
      };
    }

    else {
      die 'Invalid cache record';
    }

    return \%h;
  });
}


#==============================================================================

get '/finds' => sub ($c) {
  my $db = $c->sqlite->db;
  $c->render(
    json => caches($db->query(q{select * from finds})->hashes)->to_array
  );
};

get '/hides' => sub ($c) {
  my $db = $c->sqlite->db;
  $c->render(
    json => caches($db->query(q{select * from hides})->hashes)->to_array
  );
};


#==============================================================================

app->start;
