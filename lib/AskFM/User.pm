package AskFM::User ;

use Moose ;

has 'username' => (isa => "Str",
		  is => "ro",
		  init_arg => "username",
		  required => 1) ;


sub ask {
  my ($self, $client, $question) = @_ ;

  my $robot = $client->robot ;

  my $response ;
  $response = $robot->get($self->wall_url) ;

  my $question_form = $robot->form_id("question_form") ;

  my $form_params = {authenticity_token => $question_form->value("authenticity_token"),
		     "question[question_text]" => $question } ;

  $response = $robot->post($self->wall_url . "/questions/create", $form_params) ;

  if ( $response->is_success() ) {
    return 1 ;
  }
  else {
    return undef ;
  }

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
