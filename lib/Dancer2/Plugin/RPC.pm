package Dancer2::Plugin::RPC;
use strict;
use warnings;
use v5.10.1;

our $VERSION = '1.99_03';

=head1 NAME

Dancer2::Plugin::RPC - Namespace for XMLRPC, JSONRPC2 and RESTRPC plugins

=head1 DESCRIPTION

This module contains plugins for L<Dancer2>: L<Dancer2::Plugin::RPC::XML>,
L<Dancer2::Plugin::RPC::JSON> and L<Dancer2::Plugin::RPC::REST>.

=head2 Dancer2::Plugin::RPC::XML

This plugin exposes the new keyword C<xmlrpc> that is followed by 2 arguments:
the endpoint and the arguments to configure the xmlrpc-calls at this endpoint.

=head2 Dancer2::Plugin::RPC::JSON

This plugin exposes the new keyword C<jsonrpc> that is followed by 2 arguments:
the endpoint and the arguments to configure the jsonrpc-calls at this endpoint.

=head2 Dancer2::Plugin::RPC::REST

This plugin exposes the new keyword C<restrpc> that is followed by 2 arguments:
the endpoint and the arguments to configure the restrpc-calls at this endpoint.

=head2 General arguments to xmlrpc/jsonrpc/restrpc

The dispatch table is build by endpoint.

=head3 publish => <config|pod|$coderef>

=over

=item publish => B<config>

The dispatch table is build from the YAML-config:

    plugins:
        'RPC::XML':
            '/endpoint1':
                'Module::Name1':
                    method1: sub1
                    method2: sub2
                'Module::Name2':
                    method3: sub3
            '/endpoint2':
                'Module::Name3':
                    method4: sub4

The B<arguments> argument should be empty for this publishing type.

=item publish => B<pod>

The dispatch table is build by parsing the POD for C<=for xmlrpc>,
C<=for jsonrpc> or C<=for restrpc>.

    =for xmlrpc <method_name> <sub_name>

The B<arguments> argument must be an Arrayref with module names. The
POD-directive must be in the same file as the code!

=item publish => B<$coderef>

With this publishing type, you will need to build your own dispatch table and return it.

    use Dancer2::RPCPlugin::DispatchItem;
    return {
        method1 => dispatch_item(
            package => 'Module::Name1',
            code => Module::Name1->can('sub1'),
        ),
        method2 => dispatch_item(
            package => 'Module::Name1',
            code    => Module::Name1->can('sub2'),
        ),
        method3 => dispatch_item(
            pacakage => 'Module::Name2',
            code     => Module::Name2->can('sub3'),
        ),
    };

=back

=head3 arguments => $list

This argumument is needed for publishing type B<pod> and must be a list of
module names that contain the pod (and code).

=head3 callback => $coderef

The B<callback> argument may contain a C<$coderef> that does additional checks
and should return a L<Dancer2::RPCPlugin::CallbackResult> object.

    $callback->($request, $method_name, @method_args);

Returns for success: C<< callback_success() >>

Returns for failure: C<< callback_fail(error_code => $code, error_message => $msg) >>

This is useful for ACL checking.

=head3 code_wrapper => $coderef

The B<code_wrapper> argument can be used to wrap the code (from the dispatch table).

    my $wrapper = sub {
        my $code   = shift;
        my $pkg    = shift;
        my $method = shift;
        my $instance = $pkg->new();
        $instance->$code(@_);
    };

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 AUTHOR

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
