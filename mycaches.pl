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
use SQL::Abstract::More;
use Try::Tiny;


#==============================================================================
#=== INSTANCE INITIALIZATION ==================================================
#==============================================================================

# instantiate Template Toolkit
my $tt = Template->new({
  INCLUDE_PATH => "$Bin/templates",
  ENCODING => 'utf8'
});

# connect to database
my $dbfile = 'mycaches.sqlite';
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
$dbh->{sqlite_unicode} = 1;

# SQL::Abstract
my $sql = SQL::Abstract::More->new;


#==============================================================================
#=== ROUTING ==================================================================
#==============================================================================

sub dispatch_request {

  # root rule
  '/' => sub { cache_list() },

  # show list of finds
  '/finds' => sub { cache_list(finds => 1) },
  '/finds/limit/*' => sub {
    my ($self, $limit) = @_;
    $limit = 0 if $limit !~ /^\d+$/;
    cache_list(finds => 1, limit => $limit);
  },
  '/finds/archived' => sub { cache_list(finds => 1, archived => 1) },

  # show list of hides
  '/hides' => sub { cache_list(hides => 1) },

  # open new find/hide form
  '/find/new' => sub { new_entry('find'); },
  '/hide/new' => sub { new_entry('hide'); },

  # load single hide
  '/hide/*' => sub {
    my ($self, $hide_id) = @_;
    load_entry('hide', $hide_id);
  },

  # load single find
  '/find/*' => sub {
    my ($self, $find_id) = @_;
    load_entry('find', $find_id);
  },

  # submit an find/hide
  'POST + /submit/hide + %*' => sub { submit_entry($_[1]) },
  'POST + /submit/find + %*' => sub { submit_entry($_[1]) },

  # default rule
  '' => sub {
    my ($self, $env) = @_;
    return [
      200,
      [ 'Content-Type', 'text/plain' ],
      [ 'Unhandled Request URI: ' . $env->{REQUEST_URI} ]
    ]
  }
}


#==============================================================================
#=== ROUTE HANDLERS ===========================================================
#==============================================================================

#--- function to generate list of finds ---------------------------------------

sub finds_list
{
  #--- arguments

  my %arg = @_;

  #--- other variables

  my $now = Time::Moment->now;
  my $tz = $now->strftime('%:z');

  #--- run query

  my %qry_finds = (
    -from => 'finds',
    -columns => '*',
    -order_by => { -desc => 'finds_i' }
  );

  $qry_finds{'-limit'} = $arg{limit} if $arg{limit};
  $qry_finds{'-where'} = { 'archived' => 1 } if $arg{archived};

  #--- run query

  my ($qry, @bind) = $sql->select(%qry_finds);
  my $sth = $dbh->prepare($qry);
  my $r = $sth->execute(@bind);
  my $finds = $sth->fetchall_arrayref({});

  #--- calculate age/held fields

  if(@$finds) {
    $finds = [ reverse @$finds ];
    foreach (@$finds) {

      # ignore lab caches
      next if $_->{ctype} eq 'L';

      # calculate 'age', ie. numer of days since previous find
      try {
        my $previous_find = Time::Moment->from_string($_->{prev} . "T00:00$tz");
        my $found = Time::Moment->from_string($_->{found} . "T00:00$tz");
        $_->{age} = $previous_find->delta_days($found);

      # calculate 'held', ie. number of days when I was the last finder
        my $next_find = $now->at_midnight;
        $next_find = Time::Moment->from_string($_->{next} . "T00:00$tz") if $_->{next};
        $_->{held} = $found->delta_days($next_find);
      };
    }
  }

  #--- finish

  return $finds;
}


#--- function to generate list of hides ---------------------------------------

sub hides_list
{
  #--- arguments

  my %arg = @_;

  #--- other variables

  my $now = Time::Moment->now;
  my $tz = $now->strftime('%:z');

  #--- run query

  my %qry_hides = (
    -from => 'hides',
    -columns => '*',
    -order_by => { -desc => 'hides_i' }
  );

  my ($qry, @bind) = $sql->select(%qry_hides);
  my $sth = $dbh->prepare($qry);
  my $r = $sth->execute(@bind);
  my $hides = $sth->fetchall_arrayref({});

  #--- calculate age for hides

  if(@$hides) {
    $hides = [ reverse @$hides ];
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
  }

  #--- finish

  return $hides;
}


#--- function to generate cache list ------------------------------------------

sub cache_list
{
  #--- arguments

  # following arguments are supported
  # - finds    ... only load finds
  # - hides    ... only load hides
  # - limit    ... limit the returned list to given number of entries
  # - archived ... return only archived finds

  my %arg = @_;

  #--- other variables

  my $now = Time::Moment->now;
  my ($finds, $hides);

  #--- query finds

  $finds = finds_list(%arg) if !%arg || $arg{finds};
  $hides = hides_list() if !%arg || $arg{hides};

  #--- info

  my %info;

  if(%arg) {
    $info{finds} = {} if $arg{finds};
    $info{hides} = {} if $arg{hides};
    $info{finds}{limit} = $arg{limit} if $arg{limit};
    $info{finds}{archived} = @$finds if $arg{archived};
  }

  #--- run the data through a template

  my $out;
  $tt->process(
    'mycaches.tt',
    { finds => $finds, hides => $hides, info => \%info },
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


#--- show single hide form ----------------------------------------------------

sub load_entry
{
  my ($type, $entry_id) = @_;
  my (%re, $entry);

  my ($qry, @bind) = $sql->select(
    -columns => '*',
    -from => $type . 's',
    -where => { "${type}s_i" => $entry_id }
  );

  my $sth = $dbh->prepare($qry);
  my $r = $sth->execute(@bind);
  if($r) {
    $entry = $sth->fetchrow_hashref() if $r;
    if($entry) {
      $re{status} = 'ok';
      $re{result} = $entry;
    } else {
      $re{status} = 'error';
      $re{errmsg} = sprintf('%s %d not found', $type, $entry_id);
    }
  } else {
    $re{query} = sprintf('%s (%s)', $qry, join(',', @bind));
    $re{status} = 'error';
    $re{errmsg} = $dbh->errstr;
  }

  #--- run template

  my $out;
  $re{entrytype} = $type;
  $tt->process('entry.tt', \%re, \$out) or $out = $tt->error;

  return [
    200,
    [ 'Content-Type' => 'text/html; charset=utf-8' ],
    [ encode('UTF-8', $out) ]
  ];
}


#--- update/insert a hide entry -----------------------------------------------

sub submit_entry
{
  my ($form) = @_;
  my $type = $form->{entrytype};
  my $id = $form->{"${type}s_i"};

  my %re = (
    status => 'ok',
    entrytype => $type,
    id => $id,
  );

  delete $form->{entrytype};

  try {

    #--- sanity checks

    if($type ne 'hide' && $type ne 'find') {
      $re{status} = 'error';
      $re{mesg} = "Incorrect entrytype ($type)";
      die;
    }

    if(!defined $id || $id < 1) {
      $re{status} = 'error';
      $re{mesg} = "Incorrect entry id value ($id)";
      die;
    }

    #--- first try an update

    my ($qry, @bind) = $sql->update(
      -table => "${type}s",
      -where => { "${type}s_i" => $id },
      -set => $form
    );

    my $r = $dbh->do($qry, undef, @bind);
    if(!$r) {
      $re{status} = 'error';
      $re{mesg} = "Update failed, " . $dbh->errstr;
      $re{query} = $qry;
      $re{values} = [ @bind ];
      die;
    } elsif($r > 0) {
      $re{op} = 'update';
      die;
    } if($r != 0) {
      $re{status} = 'error';
      $re{mesg} = "Unexpected UPDATE result ($r)";
      die;
    }

    #--- if update does not fail, but indicates that zero rows were updated,
    #--- try an insert instead

    ($qry, @bind) = $sql->insert(
      -into => "${type}s",
      -values => $form
    );

    $r = $dbh->do($qry, undef, @bind);
    if(!$r) {
      $re{status} = 'error';
      $re{mesg} = "Insert failed, " . $dbh->errstr;
      $re{query} = $qry;
      $re{values} = [ @bind ];
      die;
    }
    $re{op} = 'insert';
  };

  #--- finish

  my $out;
  $tt->process('submit.tt', \%re, \$out) or $out = $tt->error;

  return [
    200,
    [ 'Content-Type' => 'text/html; charset=utf-8' ],
    [ encode('UTF-8', $out) ]
  ]
}


#--- show new entry form ------------------------------------------------------

sub new_entry
{
  my $entry_type = shift;

  #--- get highest existing entry id, the new entry id will be this number
  #--- incremented by 1

  my ($qry) = $sql->select(
    -from => $entry_type . 's',
    -columns => [ "max(${entry_type}s_i)" ]
  );

  my $sth = $dbh->prepare($qry);
  my $r = $sth->execute() or die;
  my ($max) = $sth->fetchrow_array;

  #--- run template

  my (%re, $out);
  $re{entrytype} = $entry_type;
  $re{result}{"${entry_type}s_i"} = $max + 1;
  $tt->process('entry.tt', \%re, \$out) or $out = $tt->error;

  return [
    200,
    [ 'Content-Type' => 'text/html; charset=utf-8' ],
    [ encode('UTF-8', $out) ]
  ]
}


#==============================================================================
#=== EXECUTE ==================================================================
#==============================================================================

MyCaches->run_if_script;
