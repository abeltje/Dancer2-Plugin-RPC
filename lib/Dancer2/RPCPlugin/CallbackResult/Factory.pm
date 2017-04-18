package Dancer2::RPCPlugin::CallbackResult::Factory;
use warnings;
use strict;

use Params::Validate ':all';

use Exporter 'import';
our @EXPORT = qw/ callback_success callback_fail /;

=head1 NAME

Dancer2::RPCPlugin::CallbackResult - Factory for generating Callback-results.

=head1 SYNOPSIS

    use Dancer2::Plugin::RPC::JSON;
    use Dancer2::RPCPlugin::CallbackResult;
    jsonrpc '/admin' => {
        publish => 'config',
        callback => sub {
            my ($request, $rpc_method) = @_;
            if ($rpc_method =~ qr/^admin\.\w+$/) {
                return callback_success();
            }
            return callback_fail(
                error_code => -32768,
                error_message => "only admin methods allowed: $rpc_method",
            );
        },
    };

=head1 DESCRIPTION

=head2 callback_success()

Allows no arguments.

Returns an instantiated L<Dancer::RPCPlugin::CallbackResult::Success> object.

=cut

sub callback_success {
    validate_with(params => \@_, spec => {}, allow_extra => 0); # no args!
    return Dancer2::RPCPlugin::CallbackResult::Success->new();
}

=head2 callback_fail(%arguments)

Allows these named arguments:

=over

=item error_code => $code

=item error_message => $message

=back

Returns an instantiated L<Dancer::RPCPlugin::CallbackResult::Fail> object.

=cut

sub callback_fail {
    my %data = validate_with(
        params => \@_,
        spec   => {
            error_code    => {regex => qr/^[+-]?\d+$/, optional => 0},
            error_message => {optional => 0},
        },
        allow_extra => 0,
    );
    return Dancer2::RPCPlugin::CallbackResult::Fail->new(%data);
}

1;

package Dancer2::RPCPlugin::CallbackResult;
use Moo;

=head1 NAME

Dancer2::RPCPlugin::CallbackResult - Base class for callback-result.

=cut

use overload (
    '""' => sub { $_[0]->_as_string },
    fallback => 1,
);

1;

package Dancer2::RPCPlugin::CallbackResult::Success;
use Moo;

extends 'Dancer2::RPCPlugin::CallbackResult';

has success => (
    is      => 'ro',
    isa     => sub { $_[0] == 1 },
    default => 1,
);

=head1 NAME

Dancer2::RPCPlugin::CallbackResult::Success - Class for success

=head1 DESCRIPTION

=head2 new()

Constructor, does not allow any arguments.

=head2 success()

Returns 1;

=cut

sub _as_string {
    my $self = shift;
    return "success";
}

1;

package Dancer2::RPCPlugin::CallbackResult::Fail;
use Moo;

extends 'Dancer2::RPCPlugin::CallbackResult';

=head1 NAME

Dancer2::RPCPlugin::CallbackResult::Fail - Class for failure

=head2 new()

Constructor, allows named arguments:

=over

=item error_code => $code

=item error_message => $message

=back

=cut

has error_code => (
    is       => 'ro',
    isa      => sub { $_[0] =~ /^[+-]?\d+$/ },
    required => 1,
);
has error_message => (
    is       => 'ro',
    required => 1,
);
has success => (
    is      => 'ro',
    isa     => sub { $_[0] == 0 },
    default => 0,
);

sub _as_string {
    my $self = shift;
    return sprintf("fail (%s => %s)", $self->error_code, $self->error_message);
}

1;

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
