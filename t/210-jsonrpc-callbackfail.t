#! perl -w
use strict;

use Test::More;
use Plack::Test;

use HTTP::Request;
use JSON;

my $app = MyJSONRPCAppCallbackFail->to_app();
my $tester = Plack::Test->create($app);

subtest "JSONRPC Callback::Fail" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
            {
                jsonrpc => '2.0',
                id      => 42,
                method  => 'ping',
                params  => undef,
            }
        )
    );
    my $response = $tester->request($request);
    my $response_data = from_json($response->content)->{error};
    is_deeply(
        $response_data,
        {
            'code'    => '-32760',
            'message' => 'Callback failed'
        },
        "CallbackFail"
    ) or diag(explain($response_data));
};

done_testing();

BEGIN {
    package MyJSONRPCAppCallbackFail;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::JSON;
    use Dancer2::RPCPlugin::CallbackResult::Factory;

    BEGIN { set(log => 'error') }
    jsonrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
        callback  => sub {
            return callback_fail(
                error_code    => -32760,
                error_message => "Callback failed",
            );
        },
    };
    1;
}
