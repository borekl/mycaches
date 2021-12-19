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
  my $finds = MyCaches::Model::Cachelist->new(db => $self->sqlite->db);
  my $hides = MyCaches::Model::Cachelist->new(db => $self->sqlite->db);

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
    $self->stash(find => MyCaches::Model::Find->new->to_hash);
  } else {
    $self->stash(
      find => MyCaches::Model::Find->new(
        db => $self->sqlite->db,
        load => { id => $id }
      )->to_hash
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
    $self->stash(hide => MyCaches::Model::Hide->new->to_hash);
  } else {
    $self->stash(
      hide => MyCaches::Model::Hide->new(
        db => $self->sqlite->db,
        load => { id => $id }
      )->to_hash
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
    my $find = MyCaches::Model::Find->new(
      %{$self->req->params->to_hash}, db => $self->sqlite->db
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
    my $hide = MyCaches::Model::Hide->new(
      %{$self->req->params->to_hash}, db => $self->sqlite->db
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
    my $find = MyCaches::Model::Find->new(
      id => $self->stash('id'),
      db => $self->sqlite->db
    )->delete;
  }

  elsif($self->stash('entity') eq 'hide') {
    my $hide = MyCaches::Model::Hide->new(
      id => $self->stash('id'),
      db => $self->sqlite->db
    )->delete;
  }

  $self->render;
}

#------------------------------------------------------------------------------

1;
