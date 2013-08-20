package AskFM::Client ;

use WWW::Mechanize ;
use HTML::Tree ;
use HTML::TreeBuilder ;


use Moose ;

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

has 'username' => (isa => "Str",
		   is => "rw",
		   required => 1) ;

has 'password' => (isa => "Str",
		   is => "rw",
		   required => 1) ;


sub BUILD {
  my $self = shift ;
  my $args = shift ; # ocio, e' un hashref
  
  say " >>>> Sono dentro BUILD <<<<" ;
}

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

  return $questions_html->decoded_content ;
}


sub my_questions {
  my $self = shift ;

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
