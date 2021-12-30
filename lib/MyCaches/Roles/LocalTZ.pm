package MyCaches::Roles::LocalTZ;

use Moo::Role;
use Time::Moment;

# current date
has 'now' => (
  is => 'ro',
  default => sub { Time::Moment->now->at_midnight }
);

# local timezone
has 'tz' => (
  is => 'lazy',
  default => sub { $_[0]->now->strftime('%:z') }
);

1;
