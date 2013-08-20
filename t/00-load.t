#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AskFM' ) || print "Bail out!\n";
}

diag( "Testing AskFM $AskFM::VERSION, Perl $], $^X" );
