package Dancer2::Plugin::RPC::XML;
use Dancer2::Plugin;

use v5.10.1;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

with 'Dancer2::RPCPlugin';
our $VERSION = Dancer2::RPCPlugin->VERSION;

use Dancer2::RPCPlugin::CallbackResult::Factory;
use Dancer2::RPCPlugin::DispatchItem;
use Dancer2::RPCPlugin::DispatchMethodList;
use Dancer2::RPCPlugin::ErrorResponse;
use Dancer2::RPCPlugin::FlattenData;

use RPC::XML;
use RPC::XML::ParserFactory;
use Scalar::Util 'blessed';

plugin_keywords 'xmlrpc';

sub xmlrpc {
    my ($plugin, $endpoint, $config) = @_;

    my $dispatcher = $plugin->dispatch_builder(
        $endpoint,
        $config->{publish},
        $config->{arguments},
        plugin_setting(),
    )->();

    my $lister = Dancer2::RPCPlugin::DispatchMethodList->new();
    $lister->set_partial(
        protocol => 'xmlrpc',
        endpoint => $endpoint,
        methods  => [ sort keys %{ $dispatcher } ],
    );

    my $code_wrapper = $config->{code_wrapper}
        ? $config->{code_wrapper}
        : sub {
            my $code = shift;
            my $pkg  = shift;
            $code->(@_);
        };
    my $callback = $config->{callback};

    $plugin->app->log(debug => "Starting handler build: ", $lister);
    my $xmlrpc_handler = sub {
        my $dsl = shift;
        if ($dsl->app->request->content_type ne 'text/xml') {
            $dsl->pass();
        }
        $dsl->app->log(debug => "[handle_xmlrpc_request] Processing: ", $dsl->app->request->body);

        local $RPC::XML::ENCODING = $RPC::XML::ENCODING ='UTF-8';
        my $p = RPC::XML::ParserFactory->new();
        my $request = $p->parse($dsl->app->request->body);
        my $method_name = $request->name;
        $dsl->app->log(debug => "[handle_xmlrpc_call($method_name)] ", $request->args);

        if (! exists $dispatcher->{$method_name}) {
            $dsl->app->log(warning => "$endpoint/#$method_name not found, pass()");
            $dsl->pass();
        }

        $dsl->response->content_type('text/xml');
        my $response;
        my @method_args = map $_->value, @{$request->args};
        my Dancer2::RPCPlugin::CallbackResult $continue = eval {
            $callback
                ? $callback->($dsl->app->request, $method_name, @method_args)
                : callback_success();
        };

        if (my $error = $@) {
            $response = Dancer2::RPCPlugin::ErrorResponse->new(
                error_code => 500,
                error_message => $error,
            )->as_xmlrpc_fault;
            return xmlrpc_response($dsl, $response);
        }
        if (!blessed($continue) || !$continue->isa('Dancer2::RPCPlugin::CallbackResult')) {
            $response = Dancer2::RPCPlugin::ErrorResponse->new(
                error_code    => 500,
                error_message => "Internal error: 'callback_result' wrong class " . blessed($continue),
            )->as_xmlrpc_fault;
        }
        elsif (blessed($continue) && !$continue->success) {
            $response = Dancer2::RPCPlugin::ErrorResponse->new(
                error_code    => $continue->error_code,
                error_message => $continue->error_message,
            )->as_xmlrpc_fault;
        }
        else {
            my Dancer2::RPCPlugin::DispatchItem $di = $dispatcher->{$method_name};
            my $handler = $di->code;
            my $package = $di->package;

            $response = eval {
                $code_wrapper->($handler, $package, $method_name, @method_args);
            };

            $dsl->app->log(debug => "[handling_xmlrpc_response($method_name)] ", $response);
            if (my $error = $@) {
                $response = Dancer2::RPCPlugin::ErrorResponse->new(
                    error_code => 500,
                    error_message => $error,
                )->as_xmlrpc_fault;
            }
            if (blessed($response) && $response->can('as_xmlrpc_fault')) {
                $response = $response->as_xmlrpc_fault;
            }
            elsif (blessed($response)) {
                $response = flatten_data($response);
            }
        }
        return xmlrpc_response($dsl, $response);
    };

    $plugin->app->log(debug => "setting route (xmlrpc): $endpoint ", $lister);
    $plugin->app->add_route(
        method => 'post',
        regexp => $endpoint,
        code   => $xmlrpc_handler,
    );
    return $plugin;
}

sub xmlrpc_response {
    my $dsl = shift;
    my ($data) = @_;

    local $RPC::XML::ENCODING = 'UTF-8';
    my $response;
    if (ref $data eq 'HASH' && exists $data->{faultCode}) {
        $response = RPC::XML::response->new(RPC::XML::fault->new(%$data));
    }
    else {
        $response = RPC::XML::response->new($data);
    }
    $dsl->app->log(debug => "[xmlrpc_response] ", $response);
    return $response->as_string;
}

1;

__END__

=head1 NAME

Dancer2::Plugin::RPC::XML - XMLRPC Plugin for Dancer2

=head2 SYNOPSIS

In the Controler-bit:

    use Dancer2::Plugin::RPC::XMLRPC;
    xmlrpc '/endpoint' => {
        publish   => 'pod',
        arguments => ['MyProject::Admin']
    };

and in the Model-bit (B<MyProject::Admin>):

    package MyProject::Admin;
    
    =for xmlrpc rpc.abilities rpc_show_abilities
    
    =cut
    
    sub rpc_show_abilities {
        return {
            # datastructure
        };
    }
    1;

=head1 DESCRIPTION

This plugin lets one bind an endpoint to a set of modules with the new B<xmlrpc> keyword.

=head2 xmlrpc '/endpoint' => \%publisher_arguments;

=head3 C<\%publisher_arguments>

=over

=item callback => $coderef [optional]

The callback will be called just before the actual rpc-code is called from the
dispatch table. The arguments are positional: (full_request, method_name).

    my Dancer2::RPCPlugin::CallbackResult $continue = $callback
        ? $callback->(request(), $method_name, @method_args)
        : callback_success();

The callback should return a L<Dancer2::RPCPlugin::CallbackResult> instance:

=over 8

=item * on_success

    callback_success()

=item * on_failure

    callback_fail(
        error_code    => <numeric_code>,
        error_message => <error message>
    )

=back

=item code_wrapper => $coderef [optional]

The codewrapper will be called with these positional arguments:

=over 8

=item 1. $call_coderef

=item 2. $package (where $call_coderef is)

=item 3. $method_name

=item 4. @arguments

=back

The default code_wrapper-sub is:

    sub {
        my $code = shift;
        my $pkg  = shift;
        $code->(@_);
    };

=item publisher => <config | pod | \&code_ref>

The publiser key determines the way one connects the rpc-method name with the actual code.

=over

=item publisher => 'config'

This way of publishing requires you to create a dispatch-table in the app's config YAML:

    plugins:
        "RPC::XML":
            '/endpoint':
                'MyProject::Admin':
                    admin.someFunction: rpc_admin_some_function_name
                'MyProject::User':
                    user.otherFunction: rpc_user_other_function_name

The Config-publisher doesn't use the C<arguments> value of the C<%publisher_arguments> hash.

=item publisher => 'pod'

This way of publishing enables one to use a special POD directive C<=for xmlrpc>
to connect the rpc-method name to the actual code. The directive must be in the
same file as where the code resides.

    =for xmlrpc admin.someFunction rpc_admin_some_function_name

The POD-publisher needs the C<arguments> value to be an arrayref with package names in it.

=item publisher => \&code_ref

This way of publishing requires you to write your own way of building the dispatch-table.
The code_ref you supply, gets the C<arguments> value of the C<%publisher_arguments> hash.

A dispatch-table looks like:

    return {
        'admin.someFuncion' => dispatch_item(
            package => 'MyProject::Admin',
            code    => MyProject::Admin->can('rpc_admin_some_function_name'),
        ),
        'user.otherFunction' => dispatch_item(
            package => 'MyProject::User',
            code    => MyProject::User->can('rpc_user_other_function_name'),
        ),
    }

=back

=item arguments => <anything>

The value of this key depends on the publisher-method chosen.

=back

=head2 =for xmlrpc xmlrpc-method-name sub-name

This special POD-construct is used for coupling the xmlrpc-methodname to the
actual sub-name in the current package.

=head1 INTERNAL

=head2 xmlrpc_response

Serializes the data passed as an xmlrpc response.

=head2 build_dispatcher_from_config

Creates a (partial) dispatch table from data passed from the (YAML)-config file.

=head2 build_dispatcher_from_pod

Creates a (partial) dispatch table from data provided in POD.

=head1 COPYRIGHT

(c) MMXV - Abe Timmerman <abeltje@cpan.org>

=cut
