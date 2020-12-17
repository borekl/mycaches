package MyCaches::Controller::Cachelist;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use MyCaches::Model::Finds;
use MyCaches::Model::Hides;


#------------------------------------------------------------------------------
# Generate cache list
#------------------------------------------------------------------------------

sub list($self)
{
  my $db = $self->sqlite->db;
  my %json_result;

  my $finds = MyCaches::Model::Finds->new(db => $db);
  if($self->stash('finds')) {
    $self->stash(
      finds => $json_result{finds} = $finds->list(
        tail => $self->stash('limit'),
        archived => $self->stash('archived')
      )->to_array
    );
  }

  my $hides = MyCaches::Model::Hides->new(db => $db);
  if($self->stash('hides')) {
    $self->stash(
      hides => $json_result{hides} = $hides->list->to_array
    );
  }

  $self->respond_to(
    json => { json => \%json_result },
    html => sub { $self->render }
  )
}

1;
