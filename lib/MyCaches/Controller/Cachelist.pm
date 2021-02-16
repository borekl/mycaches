package MyCaches::Controller::Cachelist;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use MyCaches::Model::Cachelist;
use MyCaches::Model::Find;
use MyCaches::Model::Hide;


#------------------------------------------------------------------------------
# Generate cache list
#------------------------------------------------------------------------------

sub list($self)
{
  my %json_result;
  my $finds = MyCaches::Model::Cachelist->new(db => $self->sqlite->db);
  my $hides = MyCaches::Model::Cachelist->new(db => $self->sqlite->db);

  # filtering
  my %where;
  $where{archived} = 1 if $self->stash('archived');

  # get finds list
  if($self->stash('finds')) {
    $json_result{finds} = $finds->load(
      table => 'finds',
      tail => $self->stash('limit') // 0,
      where => \%where,
    )->to_hash;
    $self->stash(finds => $json_result{finds});
  }

  # get hides list
  if($self->stash('hides')) {
    $json_result{hides} = $hides->load(
      table => 'hides',
      tail => $self->stash('limit') // 0,
      where => \%where,
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
        id => $id
      )->to_hash
    )
  }

  $self->respond_to(
    json => { json => $self->stash('find') },
    html => sub { $self->render }
  );
}

#------------------------------------------------------------------------------
# Get find
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
        id => $id
      )->to_hash
    );
  }

  $self->respond_to(
    json => { json => $self->stash('hide') },
    html => sub { $self->render }
  );
}

#------------------------------------------------------------------------------

1;
