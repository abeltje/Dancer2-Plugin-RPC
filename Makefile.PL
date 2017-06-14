#! perl -w
use strict;
use v5.10.1;

use ExtUtils::MakeMaker '6.55_02';

WriteMakefile(
    NAME          => 'Dancer2::Plugin::RPC',
    VERSION_FROM  => 'lib/Dancer2/Plugin/RPC.pm',
    ABSTRACT_FROM => 'lib/Dancer2/Plugin/RPC.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',
    LICENSE       => 'perl',

    PREREQ_PM => {
        'Dancer2'          => '0.20',
        'Params::Validate' => '1.0',
        'RPC::XML'         => '0.56',
        'JSON'             => '2.0',
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.55_02',
    },

    BUILD_REQUIRES => {
        'Test::More'  => '0.88', # done_testing()
        'Test::Fatal' => '0.010',
    },

    MIN_PERL_VERSION => '5.010001',

    META_ADD => {
        'meta-spec' => {
            version    => 2,
        },
        'resources' => {
            homepage   => "https://github.com/abeltje/Dancer-Plugin-RPC",
            repository => {
                type   => "git",
                url    => "git://github.com/abeltje/Dancer-Plugin-RPC.git",
                web    => "https://github.com/abeltje/Dancer-Plugin-RPC",
            },
#            x_IRC      => "irc://irc.perl.org/#amsterdam.pm",
        },
    },
);