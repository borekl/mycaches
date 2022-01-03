#!/usr/bin/perl

package MyCaches::Command::find;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::Util qw(getopt);
use Data::Printer output => 'stdout';
use Try::Tiny;

use MyCaches::Model::Find;
use MyCaches::Model::Hide;

has description => 'Display selected cache';
has usage => <<EOHD;
Usage: APPLICATION find [OPTIONS]
 -c,--cache GCID  find a cache by geocaching id
 -f,--find N      find a find by row id (use -1 to show last entry)
 -H,--hide N      find a hide by row id (use -1 to show last entry)
EOHD

sub run ($self, @args)
{
  my $db = $self->app->sqlite->db;
  my @re;

  # set output encoding
  binmode(STDOUT, ':encoding(UTF-8)');

  # parse arguments
  getopt \@args,
    'c|cache=s' => \my @caches,
    'f|find=i'  => \my @finds,
    'H|hide=i' => \my @hides;

  # load caches by cacheids

  foreach my $cacheid (@caches) {
    my ($find, $hide);
    try { $find = MyCaches::Model::Find->new(
      load => { cacheid => $cacheid }, db => $db
    ) };
    try { $hide = MyCaches::Model::Hide->new(
      load => { cacheid => $cacheid }, db => $db)
    };
    push(@re, $find->to_hash) if $find;
    push(@re, $hide->to_hash) if $hide;
  }

  # load finds
  foreach my $finds_i (@finds) {
    my $find = MyCaches::Model::Find->new(
      load => { id => $finds_i }, db => $db
    );
    push(@re, $find->to_hash);
  }

  # load hides
  foreach my $hides_i (@hides) {
    my $hide = MyCaches::Model::Hide->new(
      load => { id => $hides_i }, db => $db
    );
    push(@re, $hide->to_hash);
  }

  p @re, show_dualvar => 'off' if @re;
}


1;
