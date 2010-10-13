package Lacuna::RPC::Building::Entertainment;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use URI::Encode qw(uri_encode);

sub app_url {
    return '/entertainment';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::EntertainmentDistrict';
}

sub get_lottery_voting_options {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $cache = Lacuna->cache;
    my $building = $self->get_building($empire, $building_id); 
    my @list;
    my $config = Lacuna->config;
    my $server_url = $config->get('server_url');
    foreach my $site (@{$config->get('voting_sites')}) {
        next if $cache->get($site->{url}, $empire->id);
        push @list, {
            url     => $server_url.'entertainment/vote?session_id='.$session_id.'&site_url='.uri_encode($site->{url}, 1),
            name    => $site->{name},
        };
    }
    return {
        options         => \@list,
        status          => $self->format_status($empire, $building->body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(get_lottery_voting_options));


no Moose;
__PACKAGE__->meta->make_immutable;

