package Lacuna::DB::Result::Building::Energy;

use Moose;
extends 'Lacuna::DB::Result::Building';

__PACKAGE__->table('energy');

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Energy));
};


#__PACKAGE__->typecast_map(class => {
#    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Fission',
#    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Fusion',
#    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Geo',
#    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Hydrocarbon',
#    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Reserve',
#    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Singularity',
#    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Waste',
#});

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
