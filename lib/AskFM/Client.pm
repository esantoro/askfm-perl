package AskFM::Client ;

use WWW::Mechanize ;
use HTML::Tree ;
use HTML::TreeBuilder ;

use feature 'say' ;

use Moose ;

=pod

=head1 NAME

AskFM::Client - A simple client written to interface with Ask.fm website

B<At the moment (13/09/2013) this module requires you to have an account on ask.fm>

=head1 SYNOPSIS

  ## Login into ask.fm with your credentials
  my $client = AskFM::Client->new (username => 'myusername',
                                   password=> 'mypassword') ;

  ## retrieve questions asked to you
  ## @my_questions is an array of objects of class AskFM::Question
  my @my_questions = $client->my_questions ;

  ## retrieve today's question (WARNING: NOT IMPLEMENTED YET)
  ## $today_question is an object of class AskFM::Question

  my $today_question = $client->today_question ;

  ## Lookup a certain user
  ## $otacon22 is an object of class AskFM::User

  my $otacon22 = $client->get_user "Otacon22" ;

  ## if that user exists, ask him something!
  ## NOTE: ask.fm does not return question id, so we have no 
  ## way to track questions we asked

  if ( $otacon22 ) {
    # using $client, ask $question as anonymous
    $otacon22->ask($client, "Your next job is to implement NAT66, enjoy! :P", 1) ;

    # using $client, ask $question with $client user credentials
    $otacon22->ask($client, "Your next job is to implement NAT66, enjoy! :P", 0) ;

    # in general: $user->ask($client, $question, $anonymous)
  }

  ## We want to read Otacon22's wall (assuming account otacon22 exists)
  ## @otacon22_wall is an array of object of class AskFM::Question

  my @otacon_wall = $otacon22->wall ;

=head1 DESCRIPTION

This module provides a simple interface to Ask.fm website, in order to
have fun with its users and do neat things.

B<REMEMBER NOT TO BE AN IDIOT! DON'T BE EVIL AND DON'T HARM OTHER USERS>

=head1 RETURN VALUES

Most of the times, AskFM::Client will return object (or array of objects) of
classes of the same namespace (so, objects of classes like
AskFM::{Question,User,Answer})

When, for example, a user is not found, C<undef> will be returned.

=cut


has 'username' => (isa => "Str",
		   is => "rw",
		   required => 1) ;

has 'password' => (isa => "Str",
		   is => "rw",
		   required => 1) ;

has 'BASEURL' => (isa => "Str",
		 is => "ro",
		 init_arg => undef,
		 default => "http://ask.fm/") ;

has 'LOGIN_PAGE' => (isa => "Str",
		     is => "ro",
		     default => "http://ask.fm/login",
		     init_arg => undef) ;

has 'QUESTIONS_PAGE' => (isa => "Str",
			 is => "ro",
			 init_arg => undef,
			 default => "http://ask.fm/account/questions") ;

has 'robot' => (isa => 'WWW::Mechanize',
		is => "ro",
		init_arg => undef,
		default => sub {
		  my $r = WWW::Mechanize->new( agent => "AskFM::Client"); }
	       ) ;

has 'logged_in' => (isa => "Bool",
		   is => "rw",
		   default => 0,
		   init_arg => undef) ;

### TODO: SAVE OUR USER AS INSTANCE OF AskFM::User
has 'user' => (isa => 'AskFM::User',
	      is => 'ro',
	      init_arg => undef) ;

sub login {

  my $self = shift ;
  my $robot = $self->robot ;

  my $response ;

  ## retrieve login page: needed in order to get auth token
  $response  = $robot->get( $self->LOGIN_PAGE ) ;

  ## extrapolate login form to get auth token
  my $loginform = $robot->form_id("login_form") ;

  ## actually fill the login form
  my $login_params = {authenticity_token => $loginform->value("authenticity_token"),
		      login => $self->username,
		      password => $self->password} ;

  ## LOGIN!
  my $wall = $robot->submit_form(form_id => "login_form",
				 fields => $login_params) ;

  ## We're logged in now (assuming everything went ok)
  #say $wall->decoded_content ;

  my $questions_html = $robot->get( $self->QUESTIONS_PAGE) ;

  $self->logged_in(1) ;

  return ;
}


sub my_questions {

  my $self = shift ;

  $self->login unless ($self->logged_in) ;

  my $questions_html = $self->robot->get( $self->QUESTIONS_PAGE)->decoded_content ;

  my $tree = HTML::TreeBuilder->new ; #parse($questions_html) ;
  $tree->parse($questions_html) ;


  my $root = $tree->elementify() ;

  # say $root->tag ;

  ## Question elements: elements of the tree containing a question
  my @q_elements = $root->look_down("class", "questionbox") ;

  my $n_questions = @q_elements || 0 ;


  my @questions ;

  foreach my $q (@q_elements) {
    ## id html attribute is something like 'inbox_question_58679757748'
    ## so we get 'inbox_question_' the fuck out
    my $q_id = (split '_', $q->attr("id"))[2] ;

    my $t = shift [$q->look_down("_tag", "span",
				 "dir", "ltr")] ;
    my $q_body = $t->as_text ;

    push @questions, AskFM::Question->new(id => $q_id,
					  body => $q_body) ;

    #(question => $t->as_text,
    #		       question_id => $q_id) ;

    #      $questions->{$q_id} = $q_body ;
  }

  return @questions ;
}

sub delete_all_questions {
  my $self = shift ;

  $self->login unless ($self->logged_in) ;

  # todo:
  # 1 - get $self->QUESTION_PAGE
  # 2 - get auth token
  # 3 - post to /questions/delete :
  #      _method = delete
  #      authenticity_token = (token del punto 2)
  ## auth token regexp:
  ##     s.setAttribute('value', '4Yu+w5xCgRsPH/OaMlkuSwmvuHUjAhxk0+05br5GPyM=')

  my $robot = $self->robot ;

  my $questions_html = $robot->get($self->QUESTIONS_PAGE)->decoded_content ;

  my $token_text ;
  # s.setAttribute('value', '4Yu+w5xCgRsPH/OaMlkuSwmvuHUjAhxk0+05br5GPyM=');
  ($token_text) = ($questions_html =~ /s\.setAttribute\(\'value\', \'(\S*)\'\);/) ;

  #say "Token: " . $token_text ;

  my $params = {_method => "delete",
	       authenticity_token => $token_text} ;
  my $response = $robot->post($self->BASEURL . "/questions/delete", $params) ;

  # say $response->code ;

  if ( $response->is_success ) {
    return 1 ;
  }
  else {
    return undef;
  }
}

sub ask {
  my ($self, $target, $question, $anonymous) = @_ ;

  my $robot = $self->robot ;

  if ($anonymous) {
    $self->logout if $self->logged_in ;
  }
  else {
    $self->login unless $self->logged_in ;
  }

  my $response ;
  $response = $robot->get($target->wall_url) ;

  my $question_form = $robot->form_id("question_form") ;

  my $form_params = {authenticity_token => $question_form->value("authenticity_token"),
		     "question[question_text]" => $question } ;

  $response = $robot->post($target->wall_url . "/questions/create", $form_params) ;

  if ( $response->is_success() ) {
    return 1 ;
  }
  else {
    return undef ;
  }

}

sub get_user {
  my ($self, $target) = @_ ;

  my $robot = $self->robot ;

  my $response = $robot->get($self->BASEURL . $target) ;

  # say $response->code ;

  my $user = undef ;
  if ( $response->is_success() ){
    ## create a AskFM::User object

    $user = AskFM::User->new (username => $target)
  }

  return $user ;
}

sub logout {
  my $self = shift ;

  my $robot = $self->robot ;
  my $response = $robot->get($self->BASEURL) ;

  ## Logout form has not id or name, so we have to go and search for it
  ## --> seek and destroy!!

  foreach my $form ($robot->forms) {
    if ($form->action eq "/logout" && $form->method eq "POST") {
      my $response = $robot->request($form->click()) ;

      if ($response->is_success ) {
	return 1 ;
      }
      else {
	return 0 ;
      }
    }
  }
}

sub answer {
  my ($self, $question, $answer) = @_ ;

  my $robot = $self->robot ;


  # Questions answer page is something like :
  #    http://ask.fm/snoopybbt/questions/6571366****/reply
  # where as "6571366****" is the question_id (in which, in this case,
  # i have obscured last four digits

  my $answer_url = $self->BASEURL . '/' . $self->username . '/questions/' . $question->id . '/reply' ;
  my $response = $robot->get($answer_url) ;

  ## we get the form...
  my $question_form = $robot->form_id("question_form_" . $question->id) ;

  # we fill it with an answer...
  $question_form->param("question[answer_text]", $answer) ;

  ## we submit the form..
  $response = $robot->request($question_form->click) ;

  if ($response->is_success) {
    return 1 ;
  }
  else {
    return 0 ;
  }
}


=pod

=head1 EXAMPLES

  #!perl

  use AskFM::Client ;
  use AskFM::User ;

  use feature 'say' ;

  my $client1 = AskFM::Client->new(username => "askfmt1",
				 password => "WFRVl*****") ;

  my $client2 = AskFM::Client->new(username => "askfmt2",
				password => "VFK0Hc****") ;

  my $client_snoopy = AskFM::Client->new(username => "snoopybbt",
				      password => "****") ;

  $client_snoopy->delete_all_questions ;

  my $snoopybbt = $client1->get_user("snoopybbt");

  if ($snoopybbt) {
    $client1->ask($snoopybbt, "AskFM::Client funziona bene!! (1) :D", 1) ;

    sleep 120 ;

    $client1->ask($snoopybbt, "AskFM::Client funziona bene!! (2) :D", 0) ;
  }

=cut

return 1 ;
