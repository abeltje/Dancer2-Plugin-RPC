package Dancer2::RPCPlugin;
use Moo::Role;

BEGIN { require Dancer2::Plugin::RPC; $Dancer2::RPCPlugin::VERSION = Dancer2::Plugin::RPC->VERSION; }

use Dancer2::RPCPlugin::DispatchFromConfig;
use Dancer2::RPCPlugin::DispatchFromPod;
use Dancer2::RPCPlugin::DispatchItem;

use Params::Validate ':all';

use v5.10;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

# returns xmlrpc for Dancer2::Plugin::RPC::XMLRPC
# returns jsonrpc for Dancer2::Plugin::RPC::JSONRPC
# returns restrpc for Dancer2::Plugin::RPC::RESTRPC
sub rpcplugin_tag {
    my $full_name = ref($_[0]) ? ref($_[0]) : $_[0];
    (my $proto = $full_name) =~ s/.*:://;
    return "\L${proto}";
}

sub dispatch_builder {
    my $self = shift;
    my ($endpoint, $publish, $arguments, $settings) = @_;

    given ($publish // 'config') {
        when ('config') {
            return sub {
                $self->app->log(
                    debug => "[build_dispatch_table_from_config]"
                );
                my $dispatch_builder = Dancer2::RPCPlugin::DispatchFromConfig->new(
                    plugin_object => $self,
                    plugin        => $self->rpcplugin_tag,
                    config        => $settings,
                    endpoint      => $endpoint,
                );
                return $dispatch_builder->build_dispatch_table();
            };
        }
        when ('pod') {
            return sub {
                $self->app->log(
                    debug => "[build_dispatch_table_from_pod]"
                );
                my $dispatch_builder = Dancer2::RPCPlugin::DispatchFromPod->new(
                    plugin_object => $self,
                    plugin        => $self->rpcplugin_tag,
                    packages      => $arguments,
                    endpoint      => $endpoint,
                );
                return $dispatch_builder->build_dispatch_table();
            };
        }
        default {
            return $_;
        }
    }
}

1;

__END__

=head1 NAME

Dancer2::RPCPlugin - Role to support generic dispatch-table-building

=head1 DESCRIPTION

=head2 dispatch_builder(%parameters)

=head3 Parameters

Positional:

=over

=item 1. endpoint

=item 2. publish

=item 3. arguments (list of packages for POD-publishing)

=item 4. settings (config->{plugins}{RPC::proto})

=back

=head2 rpcplugin_tag

=head3 Parameters

None.

=head3 Responses

    <jsonrpc|restrpc|xmlrpc>

=head2 dispatch_item(%parameters)

=head3 Parameters

Named:

=over

=item code => $code_ref [Required]

=item package => $package [Optional]

=back

=head3 Responses

An instance of the class L<Dancer2::RPCPlugin::DispatchItem>.

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
