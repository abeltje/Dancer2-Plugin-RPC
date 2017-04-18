#! perl -w
use strict;
use Test::More;
use Test::NoWarnings ();

use Dancer2::RPCPlugin::CallbackResult::Factory;

subtest 'Success' => sub {
    my $success = callback_success();
    isa_ok($success, 'Dancer2::RPCPlugin::CallbackResult');
    isa_ok($success, 'Dancer2::RPCPlugin::CallbackResult::Success');

    is("$success", "success", "->as_string");
};

subtest 'Fail' => sub {
    my $fail = callback_fail(
        error_code => 42,
        error_message => 'forty two',
    );
    isa_ok($fail, 'Dancer2::RPCPlugin::CallbackResult');
    isa_ok($fail, 'Dancer2::RPCPlugin::CallbackResult::Fail');

    is("$fail", "fail (42 => forty two)", "->as_string");
};

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
