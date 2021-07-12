package MyCaches::Types::Date;

use experimental 'signatures';
use Scalar::Util qw(blessed);
use Time::Moment;

#------------------------------------------------------------------------------
# Convert input dates into Time::Moment instances if necessary; supports
# an additional format of date for user convenience
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

  # convert into Time::Moment;
  my $now = Time::Moment->now;
  my $tz = $now->strftime('%:z');
  return Time::Moment->from_string($date . "T00:00$tz");
}

#------------------------------------------------------------------------------

1;
