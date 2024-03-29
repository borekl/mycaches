package MyCaches::Controller::Caches;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use MyCaches::Model::Const;
use MyCaches::Model::Find;
use MyCaches::Model::Hide;

#-------------------------------------------------------------------------------
# load list of caches
sub load($c, %arg)
{
  my $db = $c->sqlite->db;
  my $where = $arg{where} // undef;
  my $order = { -desc => $arg{table} . '_i' };

  my $result = $db->select($arg{table}, undef, $where, $order);

  my @caches;

  while(my $row = $result->hash) {
    my $cache;
    $cache = $c->myfind->set_from_db_row(%$row) if exists $row->{finds_i};
    $cache = $c->myhide->set_from_db_row(%$row) if exists $row->{hides_i};
    push(@caches, $cache);
  }

  if($arg{tail}) {
    @caches = @caches[0 .. $arg{tail}-1]
  }

  return \@caches;
}

#-------------------------------------------------------------------------------
# Convert an array of cache instances to an array of hashes
sub to_hash($caches)
{
  my @data;
  push(@data, $_->hash_for_client) foreach (@$caches);
  return \@data;
}

#------------------------------------------------------------------------------
# Generate cache list
#------------------------------------------------------------------------------

sub list ($c)
{
  my (%where_finds, %where_hides);

  # only list archived if the 'archived' option is selected
  if($c->stash('archived')) {
    $where_hides{status} = $where_finds{status} = ST_ARCHIVED;
  }

  # do not list unpublished caches to anonymous viewers
  if(!$c->session('user')) {
    $where_hides{status} = {
      '!=', [ -and => (ST_DEVEL, ST_WT_PLACE, ST_WT_PUBLISH) ]
    };
  }

  # get finds list
  if($c->stash('finds')) {
    my $finds = $c->load(
      table => 'finds',
      tail => $c->stash('limit') // 0,
      where => \%where_finds,
    );
    $c->stash(finds => to_hash($finds));
  }

  # get hides list
  if($c->stash('hides')) {
    my $hides = $c->load(
      table => 'hides',
      tail => $c->stash('limit') // 0,
      where => \%where_hides,
    );
    $c->stash(hides => to_hash($hides));
  }

  # form the response
  $c->render;
}

#------------------------------------------------------------------------------
# Get find. Expects 'id' value in the stash; this can be either row id (finds_i
# or hides_i) or 'new', if requesting new entry form.
#------------------------------------------------------------------------------

sub find($self)
{
  my $id = $self->stash('id');

  if($id eq 'new') {
    $self->stash(find => $self->myfind->hash_for_client);
  } else {
    $self->stash(find => $self->myfind->load(id => $id)->hash_for_client)
  }

  $self->render;
}

#------------------------------------------------------------------------------
# Get hide
#------------------------------------------------------------------------------

sub hide($self)
{
  my $id = $self->stash('id');

  if($id eq 'new') {
    $self->stash(hide => $self->myhide->hash_for_client);
  } else {
    $self->stash(hide => $self->myhide->load(id => $id)->hash_for_client);
  }

  $self->render;
}

#------------------------------------------------------------------------------
# Create/update handler.
#------------------------------------------------------------------------------

sub save($self) {

  # find
  if($self->stash('entity') eq 'find') {
    my $find = $self->myfind(
      $self->req->params->to_hash->%*,
      status => ST_ACTIVE
    );
    if($self->param('finds_i')) {
      $find->update;
      $self->stash(op => 'update');
    } else {
      $find->create;
      $self->stash(op => 'create', id => $find->id);
    }
    $self->render;
  }

  # hide
  elsif($self->stash('entity') eq 'hide') {
    my $hide = $self->myhide($self->req->params->to_hash->%*);
    if($self->param('hides_i')) {
      $hide->update;
      $self->stash(op => 'update');
    } else {
      $hide->create;
      $self->stash(op => 'create', id => $hide->id);
    }
    $self->render;
  }

  # neither hide nor find
  else {
    die 'Entity not find nor hide';
  }
}

#------------------------------------------------------------------------------
# Delete handler
#------------------------------------------------------------------------------

sub delete ($self)
{
  if($self->stash('entity') eq 'find') {
    my $find = $self->myfind(id => $self->stash('id'))->delete;
  }

  elsif($self->stash('entity') eq 'hide') {
    my $hide = $self->myhide(id => $self->stash('id'))->delete;
  }

  $self->render;
}

#------------------------------------------------------------------------------

1;
