package Dancer2::Plugin::RPC::RESTRPC;
use Dancer2::Plugin;
use namespace::autoclean;

use v5.10.1;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

with 'Dancer2::RPCPlugin';
our $VERSION = Dancer2::RPCPlugin->VERSION;

use Dancer2::RPCPlugin::CallbackResult::Factory;
use Dancer2::RPCPlugin::DispatchItem;
use Dancer2::RPCPlugin::DispatchMethodList;
use Dancer2::RPCPlugin::ErrorResponse;
use Dancer2::RPCPlugin::FlattenData;

use JSON;
use Scalar::Util 'blessed';

plugin_keywords 'restrpc';

sub restrpc {
    my ($plugin, $base_url, $config) = @_;

    my $dispatcher = $plugin->dispatch_builder(
        $base_url,
        $config->{publish},
        $config->{arguments},
        plugin_setting(),
    )->();

    my $lister = Dancer2::RPCPlugin::DispatchMethodList->new();
    $lister->set_partial(
        protocol => __PACKAGE__->rpcplugin_tag,
        endpoint => $base_url,
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
    my $restrpc_handler = sub {
        my $dsl = shift;
        if ($dsl->app->request->content_type ne 'application/json') {
            $dsl->pass();
        }
        $dsl->app->log(debug => "[handle_restrpc_request] Processing: ", $dsl->app->request->body);

        my $request = $dsl->app->request;
        my $method_args = $request->body
            ? from_json($request->body)
            : undef;
        my ($method_name) = $request->path =~ m{$base_url/(\w+)};
        $dsl->app->log(debug => "[handle_restrpc_call($method_name)] ", $method_args);

        $dsl->response->content_type('application/json');
        my $response;
        my Dancer2::RPCPlugin::CallbackResult $continue = eval {
            $callback
                ? $callback->($request, $method_name, $method_args)
                : callback_success();
        };

        if (my $error = $@) {
            $response = Dancer2::RPCPlugin::ErrorResponse->new(
                error_code    => 500,
                error_message => $error,
            )->as_restrpc_error;
        }
        elsif (! $continue->success) {
            $response = Dancer2::RPCPlugin::ErrorResponse->new(
                error_code    => $continue->error_code,
                error_message => $continue->error_message,
            )->as_restrpc_error;
        }
        else {
            my Dancer2::RPCPlugin::DispatchItem $di = $dispatcher->{$method_name};
            my $handler = $di->code;
            my $package = $di->package;

            $response = eval {
                $code_wrapper->($handler, $package, $method_name, $method_args);
            };

            $dsl->app->log(debug => "[handling_restrpc_response($method_name)] ", $response);
            if (my $error = $@) {
                $response = Dancer2::RPCPlugin::ErrorResponse->new(
                    error_code => 500,
                    error_message => $error,
                )->as_restrpc_error;
            }
            if (blessed($response) && $response->can('as_restrpc_error')) {
                $response = $response->as_restrpc_error;
            }
            elsif (blessed($response)) {
                $response = flatten_data($response);
            }
        }

        $response = { RESULT => $response } if !ref($response);
        return to_json($response);
    };

    for my $call (keys %{ $dispatcher }) {
        my $endpoint = "$base_url/$call";
        $plugin->app->log(debug => "setting route (restrpc): $endpoint ", $lister);
        $plugin->app->add_route(
            method => 'post',
            regexp => $endpoint,
            code   => $restrpc_handler,
        );
    }
    return $plugin;
}

1;

__END__

=head1 NAME

Dancer2::Plugin::RPC::REST - RESTRPC Plugin for Dancer

=head2 SYNOPSIS

In the Controler-bit:

    use Dancer2::Plugin::RPC::REST;
    restrpc '/base_url' => {
        publish   => 'pod',
        arguments => ['MyProject::Admin']
    };

and in the Model-bit (B<MyProject::Admin>):

    package MyProject::Admin;
    
    =for restrpc rpc_abilities rpc_show_abilities
    
    =cut
    
    sub rpc_show_abilities {
        return {
            # datastructure
        };
    }
    1;

=head1 DESCRIPTION

RESTRPC is a simple protocol that uses HTTP-POST to post a JSON-string (with
C<Content-Type: application/json> to an endpoint. This endpoint is the
C<base_url> concatenated with the rpc-method name.

This plugin lets one bind a base_url to a set of modules with the new B<restrpc> keyword.

=head2 restrpc '/base_url' => \%publisher_arguments;

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
        my $code   = shift;
        my $pkg    = shift;
        my $method = shift;
        $code->(@_);
    };

=item publisher => <config | pod | \&code_ref>

The publiser key determines the way one connects the rpc-method name with the actual code.

=over

=item publisher => 'config'

This way of publishing requires you to create a dispatch-table in the app's config YAML:

    plugins:
        "RPC::REST":
            '/base_url':
                'MyProject::Admin':
                    admin.someFunction: rpc_admin_some_function_name
                'MyProject::User':
                    user.otherFunction: rpc_user_other_function_name

The Config-publisher doesn't use the C<arguments> value of the C<%publisher_arguments> hash.

=item publisher => 'pod'

This way of publishing enables one to use a special POD directive C<=for restrpc>
to connect the rpc-method name to the actual code. The directive must be in the
same file as where the code resides.

    =for restrpc admin_someFunction rpc_admin_some_function_name

The POD-publisher needs the C<arguments> value to be an arrayref with package names in it.

=item publisher => \&code_ref

This way of publishing requires you to write your own way of building the dispatch-table.
The code_ref you supply, gets the C<arguments> value of the C<%publisher_arguments> hash.

A dispatch-table looks like:

    return {
        'admin_someFuncion' => dispatch_item(
            package => 'MyProject::Admin',
            code    => MyProject::Admin->can('rpc_admin_some_function_name'),
        ),
        'user_otherFunction' => dispatch_item(
            package => 'MyProject::User',
            code    => MyProject::User->can('rpc_user_other_function_name'),
        ),
    }

=back

=item arguments => <anything>

The value of this key depends on the publisher-method chosen.

=back

=head2 =for restrpc restrpc-method-name sub-name

This special POD-construct is used for coupling the restrpc-methodname to the
actual sub-name in the current package.

=head1 INTERNAL

=head2 build_dispatcher_from_config

Creates a (partial) dispatch table from data passed from the (YAML)-config file.

=head2 build_dispatcher_from_pod

Creates a (partial) dispatch table from data provided in POD.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
