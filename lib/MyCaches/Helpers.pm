package MyCaches::Helpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::DOM::HTML qw(tag_to_html);
use Mojo::ByteStream;
use utf8;

# This module defines few tag helper functions for use in templates; the
# structure of the code below is derived from Mojolicious/Plugin/TagHelpers.pm

sub _bs { Mojo::ByteStream->new(@_) }

sub _tag { Mojo::ByteStream->new(tag_to_html(@_)) }

sub register
{
  my ($self, $app) = @_;

  $app->helper( typeicon => sub { _typeicon(@_)} );
  $app->helper( rating => sub { _rating(@_)} );
  $app->helper( cachename => sub { _cachename(@_)} );
  $app->helper( cachebadges => sub { _cachebadges(@_)} );
}

# Additional utility function that evaluates to 1 when argument has fractional
# part

sub _frac { $_[0] - int($_[0]) ? 1 : 0 }

# Put up geocache type icon; Groundspeak's SVG file contains symbols for all
# cache types, including cache icons for disabled caches; symbol names are
# 'icon-N' or 'icon-N-disabled' where N is icon type number that we are storing
# in 'ctype' field; the argument is either hashref of database row or cache
# type as scalar value

sub _typeicon
{
  my ($c, $item) = @_;

  my $ctype = ref $item ? $item->{ctype} : $item;
  my $status = ref $item ? $item->{status} : 1;

  my $icon = 'icon-' . $ctype;
  $icon .= '-disabled' if defined $status && $status != 1;
  _tag('svg',
    _tag('use', 'xlink:href' => "/cache-types.svg#$icon")
  );
}

# show difficulty/terrain ratings using stars; half-stars are realized as
# middle gray stars

sub _rating
{
  my ($c, $item) = @_;
  my $asterisk = '★';
  my $r = '';

  if(($item->{status} // 0) < 3 && ($item->{difficulty} || $item->{terrain})) {
    $r .= $asterisk x int($item->{difficulty});
    $r .= tag_to_html(
      'span', class => 'hlf',
      $asterisk x _frac($item->{difficulty})
    );
    $r .= '<br>';
    $r .= $asterisk x int($item->{terrain});
    $r .= tag_to_html(
      'span', class => 'hlf',
      $asterisk x _frac($item->{terrain})
    );
  }
  return _bs($r);
}

# show cachename; this handles adding a link to photo gallery if one exists

sub _cachename
{
  my ($c, $item) = @_;
  my %attr;

  $attr{class} = 'archived' if $item->{archived};
  $attr{class} = 'disabled' if defined $item->{status} && $item->{status} == 2;

  if($item->{gallery}) {
    my $span = tag_to_html('span', class => 'emoji', '&#x1f4f7;');
    my $ahref = tag_to_html('a',
      target => '_blank',
      href => 'https://voyager.lupomesky.cz/fotky/gc/'
      . $item->{cacheid} . '/', $item->{name}
    );
    _tag('div', %attr, _bs($ahref, $span)->html_unescape);
  } else {
    _tag('div', %attr, $item->{name});
  }
}

# add FTF/STF/TTF and favorite icons if needed

sub _cachebadges
{
  my ($c, $item) = @_;

  if($item->{xtf} || $item->{favorite}) {
    my $badges = '';
    $badges .= '&#x1f499' if $item->{favorite};
    $badges .= '&#x1f947' if $item->{xtf} == 1;
    $badges .= '&#x1f948' if $item->{xtf} == 2;
    $badges .= '&#x1f949' if $item->{xtf} == 3;
    _tag('div', class => 'emoji', $badges)->html_unescape;
  } else {
    '';
  }

}


1;
