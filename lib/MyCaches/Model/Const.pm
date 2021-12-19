package MyCaches::Model::Const;

# Define some constants

use Exporter 'import';

our @EXPORT = qw(
  ST_UNDEF ST_ACTIVE ST_DISABLED ST_DEVEL ST_WT_PLACE ST_WT_PUBLISH ST_ARCHIVED
);

# constants for finds.status and hides.status
use constant ST_UNDEF      => 0;
use constant ST_ACTIVE     => 1;
use constant ST_DISABLED   => 2;
use constant ST_DEVEL      => 3;
use constant ST_WT_PLACE   => 4;
use constant ST_WT_PUBLISH => 5;
use constant ST_ARCHIVED   => 6;

1;
