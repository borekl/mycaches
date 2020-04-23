#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use JSON::MaybeXS;
use DBI;
use Plack::Request;
use Plack::Response;
use Plack::Handler::CGI;

my $app = sub {
  my $req = Plack::Request->new(shift);
  my $res = Plack::Response->new(200);
  my $json = decode_json($req->content) if $req->content;

  my $dbfile = 'mycaches.sqlite';
  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
  $dbh->{sqlite_unicode} = 1;

  my $finds = $dbh->selectall_arrayref(
    'SELECT * FROM finds ORDER BY finds_i',
    { Slice => {} }
  );

  my $hides = $dbh->selectall_arrayref(
    'SELECT * FROM hides ORDER BY hides_i',
    { Slice => {} }
  );

  $res->headers([ 'Content-type' => 'application/json' ]);
  $res->body(encode_json({ finds => $finds, hides => $hides }));
  $res->finalize;
};

Plack::Handler::CGI->new->run($app);
