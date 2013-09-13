package AskFM::User ;

=pod

=head1 NAME

AskFM::User - A class representing an Ask.fm user

=head1 SYNOPSIS

  # create user:
  my $user = AskFM::User->new (username => "snoopybbt") ;
  
  # using a previously instantiated client, ask user something:
  $user->ask($client, $question, $anonymous) ;

=cut

use Moose ;

has 'username' => (isa => "Str",
		  is => "ro",
		  init_arg => "username",
		  required => 1) ;


sub ask {
  my ($self, $client, $question, $anonymous) = @_ ;

  return $client->ask($self, $question, $anonymous) ;
}

sub wall {
  my $self = shift ;

  ## return user's last answers
}

sub wall_url {
  my $self = shift ;
  return "http://ask.fm/" . $self->username ;
}

return 1 ;
