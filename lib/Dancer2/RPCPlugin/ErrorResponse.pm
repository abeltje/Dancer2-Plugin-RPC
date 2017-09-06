package Dancer2::RPCPlugin::ErrorResponse;
use Moo;

use Exporter 'import';
our @EXPORT = qw/error_response/;
sub error_response { __PACKAGE__->new(@_) }

has error_code => (
    is       => 'ro',
    required => 1
);
has error_message => (
    is       => 'ro',
    required => 1
);
has error_data => (
    is       => 'ro',
    required => 0
);

sub as_xmlrpc_fault {
    my $self = shift;
    return {
        faultCode   => $self->error_code,
        faultString => $self->error_message,
    };
}

sub as_jsonrpc_error {
    my $self = shift;

    my $data = $self->error_data;
    return {
        error => {
            code    => $self->error_code,
            message => $self->error_message,
            ($data ? (data => $data) : ()),
        }
    };
}

sub as_restrpc_error {
    my $self = shift;

    my $data = $self->error_data;
    return {
        error => {
            code => $self->error_code,
            message => $self->error_message,
            ($data ? (data => $data) : ()),
        }
    };
}


1;

=head1 NAME

Dancer2::RPCPlugin::ErrorResponse - Interface to pass error-responses without knowlage of the protocol

=head1 SYNOPSIS

    use Dancer2::RPCPlugin::ErrorResponse;

    sub handle_rpc_call {
        ...
        return error_response(
            error_code => 42,
            error_message => 'That went belly-up',
        );
    }

=head1 DESCRIPTION

=head2 error_response(%parameters)

Factory function that retuns an instantiated L<Dancer2::RPCPlugin::ErrorResponse>.

=head3 Parameters

=over

=item error_code => $error_code [required]

=item error_message => $error_message [required]

=item error_data => $error_data [optional]

=back

=head3 Responses

An instance or an exception from L<Moo>.

=head2 Dancer2::RPCPlugin::ErrorResponse->new(%parameters)

=head3 Parameters

=over

=item error_code => $error_code [required]

=item error_message => $error_message [required]

=item error_data => $error_data [optional]

=back

=head3 Responses

An instance or an exception from L<Moo>.

=head2 $er->error_code

Getter for the C<error_code> attribute.

=head2 $er->error_message

Getter for the C<error_message> attribute.

=head2 $er->error_data

Getter for the C<error_data> attribute.

=head2 $er->as_jsonrpc_error

Returns a data-structure for the use in the C<error> field of a jsonrpc response.

=head2 $er->as_xmlrpc_fault

Returns a data-structure for the use as a C<fault> response in XMLRPC.

=head2 $er->as_restrpc_error

Returns a data-structure like the C<error-field> in a JSONRPC2 error response.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abetim@cpan.org>

=cut
