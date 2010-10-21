package Lacuna::RPC::Building::OreStorage;

use Moose;
use utf8;
no warnings qw(uninitialized);
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
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    my %ores;
    my $body = $building->body;
    foreach my $ore (ORE_TYPES) {
        $ores{$ore} = $body->type_stored($ore);
    }
    $out->{ore_stored} = \%ores;
    return $out;
};

no Moose;
__PACKAGE__->meta->make_immutable;

