package AskFM::User ;

use Moose ;

has 'username' => (isa => "Str",
		  is => "ro",
		  init_arg => "username",
		  required => 1) ;
