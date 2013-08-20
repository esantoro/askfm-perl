package AskFM::Question ;

use Moose ;

has 'id' => (is => "ro",
	     isa => "Int",
	     required => 1) ;


has 'body' => (is => "ro",
	       isa => "Str",
	       required => 1) ;
