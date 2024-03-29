use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT  => 'Geocaching personal finds and hides database',
  AUTHOR    => 'Borek Lupomesky <borek@lupomesky.cz>',
  VERSION   => '0.01',
  PREREQ_PM => {
    'Mojolicious' => '9.0'
    'Mojo::SQLite' => '3.004',
    'Try::Tiny' => '0.30',
    'Data::Printer' => '1.000001',
    'Time::Moment' => '0.44',
    'Moo' => '2.003004',
    'Crypt::Passphrase' => '0.001',
    'Crypt::Passphrase::Argon2' => '0.002',
    'DBD::SQLite' => '1.70',
    'DBI' => 0,
  },
  TEST_REQUIRES => {
    'Test2::V0' => '0.000144',
    'Test2::MojoX' => '0.07',
  },
  test => { TESTS => 't/*.t' }
);
