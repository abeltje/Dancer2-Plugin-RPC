#! perl -w
use strict;

use Test::More;
use Plack::Test;

use Dancer2::RPCPlugin::ErrorResponse;
use HTTP::Request;
use JSON;

my $app = MyRESTRPCApp->to_app();
my $tester = Plack::Test->create($app);

subtest "RESTRPC return ErrorResponse" => sub {
    our $CodeWrapped = sub {
        return error_response(error_code => 42, error_message => "It went wrong :(");
    };
    my $request = HTTP::Request->new(
        POST => 'endpoint/ping',
        [
            'Content-type' => 'application/json',
            'Accept'       => 'application/json',
        ]
    );

    my $response = $tester->request($request);
    my $response_error = decode_json($response->content)->{error};
    is_deeply(
        $response_error,
        {
            code => 42,
            message => 'It went wrong :(',
        },
        "::ErrorResponse was processed"
    ) or diag(explain($response));
};

done_testing();

BEGIN {
    package MyRESTRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::REST;

    BEGIN {
        set(log => 'error');
    }
    restrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
        code_wrapper => sub { $::CodeWrapped->() },
    };

    1;
}
