package Lacuna::DB::Result::Building::Water;

use Moose;
extends 'Lacuna::DB::Result::Building';

__PACKAGE__->table('water');
#
#__PACKAGE__->typecast_map(class => {
#    'Lacuna::DB::Result::Building::Water::Production' => 'Lacuna::DB::Result::Building::Water::Production',
#    'Lacuna::DB::Result::Building::Water::Purification' => 'Lacuna::DB::Result::Building::Water::Purification',
#    'Lacuna::DB::Result::Building::Water::Reclamation' => 'Lacuna::DB::Result::Building::Water::Reclamation',
#    'Lacuna::DB::Result::Building::Water::Storage' => 'Lacuna::DB::Result::Building::Water::Storage',
#});

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Water));
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
