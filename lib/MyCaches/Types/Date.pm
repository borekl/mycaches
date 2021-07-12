package MyCaches::Types::Date;

use experimental 'signatures';
use Scalar::Util qw(blessed);
use Time::Moment;

#------------------------------------------------------------------------------
# Convert input dates into Time::Moment instances if necessary; supports
# an additional formats of date for user convenience
#------------------------------------------------------------------------------

sub ingest($date)
{
  # undefined, just return
  return undef if !defined $date;

  # already a Time::Moment instance, just return
  return $date if blessed $date && $date->isa('Time::Moment');

  # scalar in form DD/MM/YYYY is mangled into ISO date
  if($date =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/) {
    $date = sprintf('%04d-%02d-%02d', $3, $2, $1);
  }

  # get current date/timezone
  my $now = Time::Moment->now->at_midnight;
  my $tz = $now->strftime('%:z');

  # date specified as relative offset in days
  if($date =~ /^-?\d+$/) {
    return $now->plus_days($date);
  }

  # convert into Time::Moment;
  return Time::Moment->from_string($date . "T00:00$tz");
}

#------------------------------------------------------------------------------

1;
