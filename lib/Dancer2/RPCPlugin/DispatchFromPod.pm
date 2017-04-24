package Dancer2::RPCPlugin::DispatchFromPod;
use Moo;

use Dancer2::RPCPlugin::DispatchItem;
use Params::Validate ':all';
use Pod::Simple::PullParser;
use Scalar::Util 'blessed';

has plugin => (
    is       => 'ro',
    isa      => sub { blessed($_[0]) },
    required => 1,
);
has label => (
    is       => 'ro',
    isa      => sub { $_[0] =~ qr/^(?:jsonrpc|xmlrpc)$/ },
    required => 1,
);
has packages => (
    is       => 'ro',
    isa      => sub { ref($_[0]) eq 'ARRAY' },
    required => 1,
);

sub build_dispatch_table {
    my $self = shift;
    my $app = $self->plugin->app;

    my $pp = Pod::Simple::PullParser->new();
    $pp->accept_targets($self->label);
    $app->log(debug => "[dispatch_table_from_pod] for @{[$self->label]}");

    my %dispatch;
    for my $package (@{ $self->packages }) {
        eval "require $package;";
        if (my $error = $@) {
            $app->log(error => "Cannot load '$package': $error");
            die "Cannot load $package ($error) in build_dispatch_table_from_pod\n";
        }
        my $pkg_dispatch = $self->_parse_file(
            package => $package,
            parser  => $pp,
        );
        @dispatch{keys %$pkg_dispatch} = @{$pkg_dispatch}{keys %$pkg_dispatch};
    }

    my $dispatch_dump = do {
        require Data::Dumper;
        local ($Data::Dumper::Indent, $Data::Dumper::Terse, $Data::Dumper::Sortkeys) = (0, 1, 1);
        Data::Dumper::Dumper(\%dispatch);
    };

    $app->log(debug => "[dispatch_table_from_pod]->", $dispatch_dump);
    return \%dispatch;
}

sub _parse_file {
    my $self = shift;
    my $args = validate(
        @_,
        {
            package => { regex => qr/^\w[\w:]*$/ },
            parser  => { type  => OBJECT },
        }
    );
    my $app = $self->plugin->app;

    (my $pkg_as_file = "$args->{package}.pm") =~ s{::}{/}g;
    my $pkg_file = $INC{$pkg_as_file};
    use autodie;
    open my $fh, '<', $pkg_file;

    my $p = $args->{parser};
    $p->set_source($fh);

    my $dispatch;
    while (my $token = $p->get_token) {
        next if not ($token->is_start && $token->is_tag('for'));

        my $label = $token->attr('target');

        my $ntoken = $p->get_token;
        while (!$ntoken->can('text')) { $ntoken = $p->get_token; }

        $app->log(debug => "=for-token $label => ", $ntoken->text);
        my ($if_name, $code_name) = split " ", $ntoken->text;
        if (!$code_name) {
            $app->log(
                error => sprintf(
                    "[build_dispatcher] POD error $label => %s <=> %s in %s line %u",
                    $if_name // '>rpcmethod-name-missing<',
                    '>sub-name-missing<',
                    $pkg_file,
                    $token->attr('start_line')
                ),
            );
            next;
        }
        $app->log(debug => "[build_dispatcher] $args->{package}\::$code_name => $if_name");

        my $pkg = $args->{package};
        if (my $handler = $pkg->can($code_name)) {
            $dispatch->{$if_name} = Dancer2::RPCPlugin::DispatchItem->new(
                package => $pkg,
                code    => $handler
            );
        } else {
            die "Handler not found for $if_name: $pkg\::$code_name doesn't seem to exist.\n";
        }
    }
    return $dispatch;
}

1;

__END__

=head1 NAME

Dancer2::RPCPlugin::DispatchFromPod - Build dispatch-table from POD

=head1 SYNOPSIS

    use Dancer2::RPCPlugin::DispatchFromConfig;
    sub dispatch_call {
        my $config = plugin_setting();
        my $dtb = Dancer2::RPCPlugin::DispatchFromConfig->new(
            ...
        );
        return $dtb->build_dispatch_table();
    }


=head1 DESCRIPTION

This parses the text of the given packages, looking for Dispatch Table hints:

    =for xmlrpc rpc-method real-sub
    
    =for jsonrpc rpc-method real-sub

=head2 Dancer2::RPCPlugin::DispatchFromPod->new(%parameters)

=head3 Parameters

=over

=item plugin => An intance of the current plugin

=item label => <jsonrpc|xmlrpc>

=item packages => a list (ArrayRef) of package names to be parsed

=back

=head2 $dfp->build_dispatch_table()

=head3 Parameters

None

=head3 Responses

A hashref of rpc-method names as key and L<Dancer2::RPCPlugin::DispatchItem>
objects as values.

=head1 COPYRIGHT

(c) MMXV - Abe Timmerman <abeltje@cpan.org>

=cut
