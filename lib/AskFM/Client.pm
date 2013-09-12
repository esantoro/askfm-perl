package AskFM::Client ;

use WWW::Mechanize ;
use HTML::Tree ;
use HTML::TreeBuilder ;

use feature 'say' ;

use Moose ;

=pod

=head1 NAME

AskFM::Client - A simple client written to interface with Ask.fm website

=head1 SYNOPSIS

  ## Login into ask.fm with your credentials
  my $client = AskFM::Client->new (username => 'myusername',
                                   password=> 'mypassword') ;

  ## retrieve questions asked to you
  ## @my_questions is an array of objects of class AskFM::Question
  my @my_questions = $client->my_questions ;

  ## retrieve today's question
  ## $today_question is an object of class AskFM::Question

  my $today_question = $client->today_question ;

  ## Lookup a certain user
  ## $otacon22 is an object of class AskFM::User

  my $otacon22 = $client->get_user "Otacon22" ;

  ## if that user exists, ask him something ?
  ## $question_asked is an object of class AskFM::Question

  my $question_asked ;
  if ( $otacon22 ) {
    $question_asked = $otacon22->ask("Your next job is to implement NAT66, enjoy! :P") ;
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
  return ; # $questions_html->decoded_content ;
}


sub my_questions {
  my $self = shift ;

  $self->login unless ($self->logged_in) ;

  my $tree = HTML::TreeBuilder->new_from_file("./questions.html") ;

  my $root = $tree->elementify() ;

  # say $root->tag ;

  ## Question elements: elements of the tree containing a question
  my @q_elements = $root->look_down("class", "questionbox") ;

  my $n_questions = @q_elements || 0 ;

  say "Hai $n_questions domande a cui rispondere" ;

  say "Le domande: " ;

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

  #todo: 
  # 1 - get $self->QUESTION_PAGE
  # 2 - get auth token
  # 3 - post to /questions/delete :
  #      _method = delete
  #      authenticity_token = (token del punto 2)
  ## auth token regexp:  s.setAttribute('value', '4Yu+w5xCgRsPH/OaMlkuSwmvuHUjAhxk0+05br5GPyM=')

  my $robot = $self->robot ;

  my $questions_html = $robot->get($self->QUESTIONS_PAGE)->decoded_content ;

  my $token_text ;
  # s.setAttribute('value', '4Yu+w5xCgRsPH/OaMlkuSwmvuHUjAhxk0+05br5GPyM=');
  ($token_text) = ($questions_html =~ /s\.setAttribute\(\'value\', \'(\S*)\'\);/) ;

  say "Token: " . $token_text ;

  my $params = {_method => "delete",
	       authenticity_token => $token_text} ;
  my $response = $robot->post($self->BASEURL . "/questions/delete", $params) ;

  say $response->code ;

  return $response->code ;
}

return 1 ;
