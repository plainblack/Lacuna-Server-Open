package Lacuna::RPC::Building::OreStorage;

use Moose;
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(ORE_TYPES);

sub app_url {
    return '/orestorage';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Ore::Storage';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $out = $orig->($self, $empire, $building);
    my %ores;
    my $body = $building->body;
    foreach my $ore (ORE_TYPES) {
        my $method = $ore.'_stored';
        $ores{$ore} = $body->$method();
    }
    $out->{ore_stored} = \%ores;
    return $out;
};

no Moose;
__PACKAGE__->meta->make_immutable;

