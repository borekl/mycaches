package MyCaches::Model::User;

use Mojo::Base -base, -signatures;

#------------------------------------------------------------------------------
# ATTRIBUTES
#------------------------------------------------------------------------------

has 'db';                  # ref to db connection
has 'userid';              # user id (textual)
has 'pw';                  # hashed/salted password

#------------------------------------------------------------------------------
# Create user in backend db
#------------------------------------------------------------------------------

sub create ($self)
{
  $self->db->insert('users', { userid => $self->userid, pw => $self->pw });
  return $self;
}

#------------------------------------------------------------------------------
# Update user in backend db
#------------------------------------------------------------------------------

sub update ($self)
{
  $self->db->update('users', { pw => $self->pw }, { userid => $self->userid });
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

sub check ($self, %arg)
{
  my $re = $self->db->select('users', undef, { userid => $self->userid });
  my $e = $re->hash;
  $re->finish;
  return 0 unless $e;
  return 1 if $arg{pw} eq $e->{pw};
  return 0;
}

#------------------------------------------------------------------------------

1;
