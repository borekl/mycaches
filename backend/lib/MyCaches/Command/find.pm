#!/usr/bin/perl

package MyCaches::Command::find;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::Util qw(getopt);
use Data::Printer output => 'stdout';
use Try::Tiny;

has description => 'Display selected cache';
has usage => <<EOHD;
Usage: APPLICATION find [OPTIONS]
 -c,--cache GCID  find a cache by geocaching id
 -f,--find N      find a find by row id (use -1 to show last entry)
 -H,--hide N      find a hide by row id (use -1 to show last entry)
EOHD

sub run ($self, @args)
{
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
    try { $find = $self->app->myfind->load(cacheid => $cacheid) };
    try { $hide = $self->app->myhide->load(cacheid => $cacheid) };
    push(@re, $find->hash_for_client) if $find;
    push(@re, $hide->hash_for_client) if $hide;
  }

  # load finds
  foreach my $finds_i (@finds) {
    my $find = $self->app->myfind->load(id => $finds_i);
    push(@re, $find->hash_for_client);
  }

  # load hides
  foreach my $hides_i (@hides) {
    my $hide = $self->app->myhide->load(id => $hides_i);
    push(@re, $hide->hash_for_client);
  }

  p @re, show_dualvar => 'off' if @re;
}


1;
