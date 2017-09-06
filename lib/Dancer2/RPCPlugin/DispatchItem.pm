package Dancer2::RPCPlugin::DispatchItem;
use Moo;

our $VERSION = '0.10';

=head1 NAME

Dancer2::RPCPlugin::DispatchItem - Small object to handle dispatch-table items

=head1 SYNOPSIS

    use Dancer2::RPCPlugin::DispatchItem;
    use Dancer2::Plugin::RPC::JSON;
    jsonrpc '/json' => {
        publish => sub {
            return {
                'system.ping' => Dancer2::RPCPlugin::DispatchItem->new(
                    code    => MyProject::Module1->can('sub1'),
                    package => 'Myproject::Module1',
                ),
            };
        },
    };


=cut

has code => (
    is       => 'ro',
    required => 1
);
has package => (
    is       => 'ro',
    required => 1
);

=head1 DESCRIPTION

=head2 Dancer2::RPCPlugin::DispatchItem->new(%arguments)

=head3 Parameters

Named:

=over

=item code => $code_ref [Required]

=item package => $package [Optional]

=back

=head2 $di->code

Getter for the C<code> attibute.

=head2 $di->package

Getter for the C<package> attribute

=cut

#sub new {
#    my $class = shift;
#    my $self = validate_with(
#        params => \@_,
#        spec => {
#            code    => {optional => 0},
#            package => {optional => 1},
#        },
#        allow_extra => 0,
#    );
#    return bless $self, $class;
#}
#sub code    { $_[0]->{code} }
#sub package { $_[0]->{package} // '' }

1;

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abetim@cpan.org>

=cut
