#! perl -w
use strict;

use constant Dancer2_Plugin_Methods => [ qw/
    ClassHooks
    PluginKeyword
    dancer_app
    execute_plugin_hook
    hook
    keywords
    on_plugin_import
    plugin_args
    plugin_setting
    register
    register_hook
    register_plugin
    request
    var
/];

use Test::Pod::Coverage;

all_pod_coverage_ok({trustme => Dancer2_Plugin_Methods});
