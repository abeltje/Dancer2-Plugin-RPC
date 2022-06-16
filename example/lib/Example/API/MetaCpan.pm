package Example::API::MetaCpan;
use Moo;
use Types::Standard qw( InstanceOf );

with qw(
    Example::ValidationTemplates
    MooX::Params::CompiledValidators
);

our $VERSION = '2.00';

has mc_client => (
    is       => 'ro',
    isa      => InstanceOf['Example::Client::MetaCpan'],
    required => 1
);

sub mc_search {
    my $self = shift;
    $self->validate_parameters(
        { $self->parameter(query => $self->Required, {store => \my $query}) },
        $_[0]
    );
    my $response = $self->mc_client->call($query);
    if (exists $response->{hits}) {
        my @hits = map {
            {
                author       => $_->{_source}{author},
                date         => $_->{_source}{date},
                distribution => $_->{_source}{distribution},
                module       => $_->{_source}{main_module},
                name         => $_->{_source}{name},
                version      => $_->{_source}{version},
            }
        } sort {
               $a->{_source}{main_module} cmp $b->{_source}{main_module}
            || $a->{_source}{version_numified} <=> $b->{_source}{version_numified}
        } @{ $response->{hits}{hits} };

        return {hits => \@hits};
    }
    return {hits => [ ]};
}

use namespace::autoclean;
1;

=head1 NAME

MetaCpan - Interface to  MetaCpan (https://fastapi.metacpan.org/v1/release/_search)

=head1 SYNOPSIS

    use MetaCpanClient;
    use MetaCpan;
    my $mc_client = MetaCpanClient->new(
        base_uri => 'https://fastapi.metacpan.org/v1/release/_search',
    );
    my $mc = MetaCpan->new(mc_client => $mc_client);

    my $hits = $mc->mc_search({query => 'Dancer::Plugin::RPC'});

=head1 DESCRIPTION

=head2 mc_search({query => $query})

Returns a summary of the hits that MetaCpan returns.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
