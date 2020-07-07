#!/usr/bin/env plackup

package MyCaches;
use Web::Simple;

use strict;
use warnings;
use utf8;
use feature 'state';

use FindBin qw($Bin);
use DBI;
use Template;
use Encode qw(encode);
use Time::Moment;


#==============================================================================
# initialization
#==============================================================================

# instantiate Template Toolkit
my $tt = Template->new({ INCLUDE_PATH => "$Bin", ENCODING => 'utf8'  });

# connect to database
my $dbfile = 'mycaches.sqlite';
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
$dbh->{sqlite_unicode} = 1;


#==============================================================================
# routes
#==============================================================================

sub dispatch_request {
  '/' => 'cache_list',
  '' => sub { [ 301, [ 'Location', '/' ], [] ] },
}


#--- function to generate cache list ------------------------------------------

sub cache_list
{
  my $now = Time::Moment->now;
  my $tz = $now->strftime('%:z');

  my $finds = $dbh->selectall_arrayref(
    'SELECT * FROM finds ORDER BY finds_i',
    { Slice => {} }
  );

  my $hides = $dbh->selectall_arrayref(
    'SELECT * FROM hides ORDER BY hides_i',
    { Slice => {} }
  );

  #--- calculate age/held fields for finds

  foreach (@$finds) {

    # ignore lab caches
    next if $_->{ctype} eq 'L';

    # calculate 'age', ie. numer of days since previous find
    my $previous_find = Time::Moment->from_string($_->{prev} . "T00:00$tz");
    my $found = Time::Moment->from_string($_->{found} . "T00:00$tz");
    $_->{age} = $previous_find->delta_days($found);

    # calculate 'held', ie. number of days when I was the last finder
    my $next_find = $now->at_midnight;
    $next_find = Time::Moment->from_string($_->{next} . "T00:00$tz") if $_->{next};
    $_->{held} = $found->delta_days($next_find);
  }

  #--- calculate age for hides

  foreach (@$hides) {

    # ignore unpublished hides
    next if !$_->{published};

    my $last_found = Time::Moment->from_string($_->{found} . "T00:00$tz")
      if $_->{found};
    my $published = Time::Moment->from_string($_->{published} . "T00:00$tz")
      if $_->{published};
    my $timeref = $last_found // $published;

    $_->{age} = $timeref->at_midnight->delta_days($now->at_midnight);
  }

  #--- run the data through a template

  my $out;
  $tt->process(
    'mycaches.tt',
    { finds => $finds, hides => $hides },
    \$out
  ) or $out = $tt->error;

  #--- get expiration time

  # we're setting expiration 10 minutes to the future, with the exception
  # that midnight always expires the page (since the age/held fields increase
  # exactly at midnight)

  my $expire = $now->plus_minutes(10);
  my $next_midnight = $now->plus_days(1)->at_midnight;
  $expire = $expire < $next_midnight ? $expire : $next_midnight;

  #--- set refresh timeout

  # we're setting the page to refresh on every midnight; this will make the
  # page stay up-to-date without user intervention

  my $seconds_to_midnight = $now->delta_seconds($next_midnight);
  $seconds_to_midnight ||= 86400;

  #--- finish

  my $headers = [
    'Content-Type' => 'text/html; charset=utf-8',
    'Expires' => $expire->at_utc->strftime('%a, %d %b %Y %H:%M:%S GMT'),
    'Refresh' => $seconds_to_midnight,
  ];

  return [ 200, $headers, [ encode('UTF-8', $out) ] ];
}


#==============================================================================
# run the request handler
#==============================================================================

MyCaches->run_if_script;
