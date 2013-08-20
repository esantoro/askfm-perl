use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AskFM',
    AUTHOR              => q{Emanuele Santoro <manu@santoro.tk>},
    VERSION_FROM        => 'lib/AskFM.pm',
    ABSTRACT_FROM       => 'lib/AskFM.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AskFM-*' },
);
