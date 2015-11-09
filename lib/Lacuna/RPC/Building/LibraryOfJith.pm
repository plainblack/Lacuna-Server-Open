package Lacuna::RPC::Building::LibraryOfJith;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/libraryofjith';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::LibraryOfJith';
}

sub research_species {
    my ($self, $session_id, $building_id, $view_empire_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $view_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($view_empire_id);
    
    unless (defined $view_empire) {
        confess [1002, 'Could not locate that empire.'];
    }
    if ($building->is_working) {
        confess [1010, 'The researchers are busy now. Come back later.'];
    }

    $building->start_work({}, 15 + ((60 * 60) * ((30-$building->effective_level)/30)));

    return {
        status  => $self->format_status($empire, $building->body),
        species => {
            name                    => $view_empire->species_name,
            description             => $view_empire->species_description,
            min_orbit               => $view_empire->min_orbit,
            max_orbit               => $view_empire->max_orbit,
            manufacturing_affinity  => $view_empire->manufacturing_affinity,
            deception_affinity      => $view_empire->deception_affinity,
            research_affinity       => $view_empire->research_affinity,
            management_affinity     => $view_empire->management_affinity,
            farming_affinity        => $view_empire->farming_affinity,
            mining_affinity         => $view_empire->mining_affinity,
            science_affinity        => $view_empire->science_affinity,
            environmental_affinity  => $view_empire->environmental_affinity,
            political_affinity      => $view_empire->political_affinity,
            trade_affinity          => $view_empire->trade_affinity,
            growth_affinity         => $view_empire->growth_affinity,
        },
    };
}


__PACKAGE__->register_rpc_method_names(qw(research_species));


no Moose;
__PACKAGE__->meta->make_immutable;

