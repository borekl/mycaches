package MyCaches::Controller::API;

use Mojo::Base 'Mojolicious::Controller', -signatures;

#-------------------------------------------------------------------------------
# Simple NOOP endpoint, suitable for verifying that user is authenticated
sub api ($self)
{
  $self->render(json => {
    status => 'ok',
    user => $self->session('user')
  });
}

1;
