package MyCaches::Misc;

# auxiliary functions

require Exporter;

use warnings;
use strict;
use experimental 'signatures';

our @ISA = qw(Exporter);
our @EXPORT = qw(
  empty_strings_to_undefs
);

# replace empty strings in hash values with undefs
sub empty_strings_to_undefs ($hash)
{
  foreach my $v (values %$hash) {
    undef $v unless length $v;
  }
}

1;
