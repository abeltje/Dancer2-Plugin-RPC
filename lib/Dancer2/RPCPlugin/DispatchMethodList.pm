package Dancer2::RPCPlugin::DispatchMethodList;
use warnings;
use strict;
use Params::Validate ':all';

=head1 NAME

Dancer2::RPCPlugin::DispatchMethodList - Class for maintaining a global methodlist.

=head1 SYNOPSIS

    use Dancer2::RPCPlugin::DispatchMethodList;
    my $methods = Dancer2::RPCPlugin::DispatchMethodList->new();

    $methods->set_partial(
        protocol => <jsonrpc|xmlrpc>,
        endpoint => </configured>,
        methods  => [ @method_names ],
    );

    # Somewhere else
    my $dml = Dancer2::RPCPlugin::DispatchMethodList->new();
    my $methods = $dml->list_methods(<any|jsonrpc|xmlrpc>);

=head1 DESCRIPTION

This class implements a singleton that can hold the collection of all method names.

=head2 my $dml = Dancer2::RPCPlugin::DispatchMethodList->new()

=head3 Parameters

None!

=head3 Responses

    $singleton = bless $parameters, $class;

=cut

my $_singleton;
sub new {
    return $_singleton if $_singleton;

    my $class = shift;
    $_singleton = bless {protocol => {}}, $class;
}

=head2 $dml->set_partial(%parameters)

=head3 Parameters

Named, list:

=over

=item protocol => <jsonrpc|xmlrpc>

=item endpoint => $endpoint

=item methods => \@method_list

=back

=head3 Responses

    $self

=cut

sub set_partial {
    my $self = shift;
    my $args = validate_with(
        params => \@_,
        spec   => {
            protocol => {regex => qr/^(?:json|rest|xml)rpc$/, optional => 0},
            endpoint => {regex => qr/^.*$/, optional => 0},
            methods  => {type => ARRAYREF},
        },
    );
    $self->{protocol}{$args->{protocol}}{$args->{endpoint}} = $args->{methods};
    return $self;
}

=head2 $dml->list_methods(@parameters)

Method that returns information about the dispatch-table.

=head3 Parameters

Positional, list:

=over

=item $protocol => undef || <any|jsonrpc|xmlrpc>

=back

=head3 Responses

In case of no C<$protocol>:

    {
        xmlrpc => {
            $endpoint1 => [ list ],
            $endpoint2 => [ list ],
        },
        jsonrpc => {
            $endpoint1 => [ list ],
            $endpoint2 => [ list ],
        },
    }

In case of specified C<$protocol>:

    {
        $endpoint1 => [ list ],
        $endpoint2 => [ list ],
    }

=cut

sub list_methods {
    my $self = shift;
    my ($protocol) = validate_pos(
        @_,
        {default => 'any', regex => qr/^(?:any|(?:json|rest|xml)rpc)$/, optional => 1}
    );
    if ($protocol eq 'any') {
        return $self->{protocol};
    }
    else {
        return $self->{protocol}{$protocol};
    }
}

1;

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
