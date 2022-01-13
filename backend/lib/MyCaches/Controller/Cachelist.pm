package MyCaches::Controller::Cachelist;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use MyCaches::Model::Cachelist;
use MyCaches::Model::Find;
use MyCaches::Model::Hide;
use MyCaches::Model::Const;

#------------------------------------------------------------------------------
# Generate cache list
#------------------------------------------------------------------------------

sub list($self)
{
  my %json_result;
  my $finds = MyCaches::Model::Cachelist->new(sqlite => $self->sqlite);
  my $hides = MyCaches::Model::Cachelist->new(sqlite => $self->sqlite);

  # filtering finds/hides
  my (%where_finds, %where_hides);

  # only list archived if the 'archived' option is selected
  if($self->stash('archived')) {
    $where_hides{status} = $where_finds{status} = ST_ARCHIVED;
  }

  # do not list unpublished caches to anonymous viewers
  if(!$self->session('user')) {
    $where_hides{status} = {
      '!=', [ -and => (ST_DEVEL, ST_WT_PLACE, ST_WT_PUBLISH) ]
    };
  }

  # get finds list
  if($self->stash('finds')) {
    $json_result{finds} = $finds->load(
      table => 'finds',
      tail => $self->stash('limit') // 0,
      where => \%where_finds,
    )->to_hash;
    $self->stash(finds => $json_result{finds});
  }

  # get hides list
  if($self->stash('hides')) {
    $json_result{hides} = $hides->load(
      table => 'hides',
      tail => $self->stash('limit') // 0,
      where => \%where_hides,
    )->to_hash;
    $self->stash(hides => $json_result{hides});
  }

  # form the response
  $self->respond_to(
    json => { json => \%json_result },
    html => sub { $self->render }
  );
}

#------------------------------------------------------------------------------
# Get find. Expects 'id' value in the stash; this can be either row id (finds_i
# or hides_i) or 'new', if requesting new entry form.
#------------------------------------------------------------------------------

sub find($self)
{
  my $id = $self->stash('id');

  if($id eq 'new') {
    $self->stash(find => $self->find->to_hash);
  } else {
    $self->stash(
      find => $self->find(load => { id => $id })->to_hash
    )
  }

  $self->respond_to(
    json => { json => $self->stash('find') },
    html => sub { $self->render }
  );
}

#------------------------------------------------------------------------------
# Get hide
#------------------------------------------------------------------------------

sub hide($self)
{
  my $id = $self->stash('id');

  if($id eq 'new') {
    $self->stash(hide => $self->hide->to_hash);
  } else {
    $self->stash(
      hide => $self->hide(load => { id => $id })->to_hash
    );
  }

  $self->respond_to(
    json => { json => $self->stash('hide') },
    html => sub { $self->render }
  );
}

#------------------------------------------------------------------------------
# Create/update handler.
#------------------------------------------------------------------------------

sub save($self) {

  # find
  if($self->stash('entity') eq 'find') {
    my $find = $self->find(
      %{$self->req->params->to_hash}, sqlite => $self->sqlite
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
    my $hide = $self->hide(
      %{$self->req->params->to_hash}, sqlite => $self->sqlite
    );
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
    my $find = $self->find(id => $self->stash('id'))->delete;
  }

  elsif($self->stash('entity') eq 'hide') {
    my $hide = $self->hide(id => $self->stash('id'))->delete;
  }

  $self->render;
}

#------------------------------------------------------------------------------

1;
