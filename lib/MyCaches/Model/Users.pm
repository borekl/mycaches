package MyCaches::Model::Users;

use Mojo::Base -base, -signatures;
use Crypt::Passphrase;

#------------------------------------------------------------------------------
# ATTRIBUTES
#------------------------------------------------------------------------------

has 'db';                  # ref to db connection
has 'userid';              # user id (textual)
has 'pw';                  # cleartext password

# hashed password
has 'hash' => sub {
  $_[0]->authenticator->hash_password($_[0]->pw);
};

# Crypt::Passphrase encoding options (with a default)
has 'auth_options' => sub {{
  encoder => {
    module => 'Argon2',
    time_cost => 1,
    memory_cost => "16M",
    parallelism => 2,
  }
}};

# Crypt::Passphrase::Encoder instance
has 'authenticator' => sub {
  Crypt::Passphrase->new($_[0]->auth_options->%*);
};

#------------------------------------------------------------------------------
# Create user in backend db
#------------------------------------------------------------------------------

sub create ($self)
{
  $self->db->insert('users', { userid => $self->userid, pw => $self->hash });
  return $self;
}

#------------------------------------------------------------------------------
# Update user in backend db
#------------------------------------------------------------------------------

sub update ($self)
{
  $self->db->update('users', { pw => $self->hash }, { userid => $self->userid });
  return $self
}

#------------------------------------------------------------------------------
# Update user in backend db
#------------------------------------------------------------------------------

sub delete ($self)
{
  $self->db->delete('users', { userid => $self->userid });
  return $self;
}

#------------------------------------------------------------------------------
# List users
#------------------------------------------------------------------------------

sub list ($self)
{
  my $re = $self->db->select(
    'users', undef, undef, { -asc => 'userid'}
  )->hashes;
  my $users = $re->sort(sub { $a->{userid} cmp $b->{userid} })->to_array;

  return map { $_->{userid} } @$users;
}

#------------------------------------------------------------------------------
# Check users password
#------------------------------------------------------------------------------

sub check ($self)
{
  my $re = $self->db->select('users', undef, { userid => $self->userid });
  my $e = $re->hash;
  $re->finish;
  return 0 unless $e;
  if($self->authenticator->verify_password($self->pw, $e->{pw})) {
    if($self->authenticator->needs_rehash($e->{pw})) {
      $self->hash($self->authenticator->hash_password($self->pw));
      $self->update;
    }
    return 1;
  }
  return 0;
}

#------------------------------------------------------------------------------

1;
