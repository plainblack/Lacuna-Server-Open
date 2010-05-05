package Lacuna::DB::Building::Energy;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->table('energy');

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Energy));
};


__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Building::Energy::' => 'Lacuna::DB::Building::Energy::Fission',
    'Lacuna::DB::Building::Energy::' => 'Lacuna::DB::Building::Energy::Fusion',
    'Lacuna::DB::Building::Energy::' => 'Lacuna::DB::Building::Energy::Geo',
    'Lacuna::DB::Building::Energy::' => 'Lacuna::DB::Building::Energy::Hydrocarbon',
    'Lacuna::DB::Building::Energy::' => 'Lacuna::DB::Building::Energy::Reserve',
    'Lacuna::DB::Building::Energy::' => 'Lacuna::DB::Building::Energy::Singularity',
    'Lacuna::DB::Building::Energy::' => 'Lacuna::DB::Building::Energy::Waste',
});

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
