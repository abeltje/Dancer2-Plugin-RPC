#! perl -w
use strict;

use Test::More;
use Test::Fatal;
use Test::MockObject;
use Test::NoWarnings ();

use Dancer2::RPCPlugin::DispatchFromPod;
use Dancer2::RPCPlugin::DispatchItem;

use lib 'ex/';
use MyAppCode;

my $logfile = "";
my $app = Test::MockObject->new->mock(
    log => sub {
        shift;
        use Data::Dumper;
        local ($Data::Dumper::Indent, $Data::Dumper::Sortkeys, $Data::Dumper::Terse) = (0, 1, 1);
        my @processed = map { ref($_) ? Data::Dumper::Dumper($_) : $_ } @_;
        $logfile = join("\n", $logfile, join(" ", @processed)); }
);
my $plugin = Test::MockObject->new->set_always(
    app => $app,
);

subtest 'Working dispatch table from POD' => sub {
    my $builder = Dancer2::RPCPlugin::DispatchFromPod->new(
        plugin   => $plugin,
        label    => 'jsonrpc',
        packages => [qw/
            MyAppCode
        /],
    );
    isa_ok($builder, 'Dancer2::RPCPlugin::DispatchFromPod', 'Builder')
        or diag("\$builder isa: ", ref $builder);
    my $dispatch = $builder->build_dispatch_table();
    is_deeply(
        $dispatch,
        {
            'ping' => Dancer2::RPCPlugin::DispatchItem->new(
                code => MyAppCode->can('do_ping'),
                package => 'MyAppCode',
            ),
            'version' => Dancer2::RPCPlugin::DispatchItem->new(
                code => MyAppCode->can('do_version'),
                package => 'MyAppCode',
            ),
            'method.list' => Dancer2::RPCPlugin::DispatchItem->new(
                code => MyAppCode->can('do_methodlist'),
                package => 'MyAppCode',
            ),
        },
        "Dispatch table from POD"
    ) or diag(explain($dispatch));
};

subtest 'Adding non existing code, fails' => sub {
    like(
        exception {
            (my $builder = Dancer2::RPCPlugin::DispatchFromPod->new(
                plugin   => $plugin,
                label    => 'jsonrpc',
                packages => [qw/
                    MyBogusApp
                /],
            ))->build_dispatch_table();
        },
        qr/Handler not found for bogus.nonexistent: MyBogusApp::nonexistent doesn't seem to exist/,
        "Setting a non-existent dispatch target throws an exception"
    );
};

subtest 'Adding non existing package, fails' => sub {
    like(
        exception {
            (my $builder = Dancer2::RPCPlugin::DispatchFromPod->new(
                plugin   => $plugin,
                label    => 'jsonrpc',
                packages => [qw/
                    MyNotExistingApp
                /],
            ))->build_dispatch_table();
        },
        qr/Cannot load MyNotExistingApp .+ in build_dispatch_table_from_pod/s,
        "Using a non existing package throws an exception"
    );
};

subtest 'POD error in =for json' => sub {
    $logfile = "";
    like(
        exception {
            (my $builder = Dancer2::RPCPlugin::DispatchFromPod->new(
                plugin   => $plugin,
                label    => 'jsonrpc',
                packages => [qw/
                    MyPoderrorApp
                /],
            ))->build_dispatch_table();
        },
        qr/Handler not found for method: MyPoderrorApp::code doesn't seem to exist/,
        "Ignore syntax-error in '=for jsonrpc/xmlrpc'"
    );
    like(
        $logfile,
        qr/^error .+ >rpcmethod-name-missing< <=> >sub-name-missing</m,
        "error log-message method and sub missing"
    );
    like(
        $logfile,
        qr/^error .+ <=> >sub-name-missing</m,
        "error log-message sub missing"
    );
};

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
