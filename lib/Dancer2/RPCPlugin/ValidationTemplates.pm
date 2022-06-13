package Dancer2::RPCPlugin::ValidationTemplates;
use Moo::Role;

use Type::Tiny;
use Types::Standard qw( ArrayRef CodeRef Dict HashRef Maybe Ref Str StrMatch );

sub ValidationTemplates {
    my $publisher_check = sub {
        my ($value) = @_;
        if (!ref($value)) {
            return $value =~ m{ ^(config | pod) $}x ? 1 : 0;
        }
        return ref($value) eq 'CODE' ? 1 : 0;
    };
    my $publisher = Type::Tiny->new(
        name       => 'Any',
        constraint => $publisher_check,
        message    => sub { "'$_' must be 'config', 'pod' or a CodeRef" },
    );
    # we cannot have Types::Standard::Optional imported
    # it interfers with our own ->Optional
    my $plugin_config = Dict [
        publish      => Types::Standard::Optional [ Maybe [$publisher] ],
        arguments    => Types::Standard::Optional [ Maybe [ArrayRef] ],
        callback     => Types::Standard::Optional [CodeRef],
        code_wrapper => Types::Standard::Optional [CodeRef],
    ];
    my $plugins = Dancer2::RPCPlugin::PluginNames->new->regex;
    return {
        endpoint => { type => StrMatch [qr{^ [\w/\\%]+ $}x] },
        publish  => {
            type    => Maybe [$publisher],
            default => 'config'
        },
        arguments     => { type => Maybe [ArrayRef] },
        settings      => { type => Maybe [HashRef] },
        protocol      => { type => StrMatch [$plugins] },
        methods       => { type => ArrayRef [ StrMatch [qr{ . }x] ] },
        config        => { type => $plugin_config },
        status_map    => { type => HashRef },
        handler_name  => { type => Maybe [Str] },
        error_handler => { type => Maybe [CodeRef] },
    };
}

use namespace::autoclean;
1;
