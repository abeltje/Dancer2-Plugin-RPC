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
        'Dancer2'                    => '0.20',
        'JSON'                       => '2.0',
        'Params::ValidationCompiler' => '0.24',
        'RPC::XML'                   => '0.56',
        'Types::Standard'            => '1.00',
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.55_02',
    },

    BUILD_REQUIRES => {
        'Test::Fatal'      => '0.01',
        'Test::MockObject' => '1.20',
        'Test::More'       => '0.88',    # done_testing()
        'Test::Warnings'   => '0.030',
    },

    MIN_PERL_VERSION => '5.010001',

    META_MERGE => {
        'meta-spec' => {
            version    => 2,
        },
        'resources' => {
            license    => [ 'perl_5'],
            homepage   => "https://github.com/abeltje/Dancer2-Plugin-RPC",
            repository => {
                type   => "git",
                url    => "git://github.com/abeltje/Dancer2-Plugin-RPC.git",
                web    => "https://github.com/abeltje/Dancer2-Plugin-RPC",
            },
#            x_IRC      => "irc://irc.perl.org/#amsterdam.pm",
        },
    },
);
