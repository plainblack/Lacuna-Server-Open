package Lacuna::DB::Building::Water;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->table('water');

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Building::Water::Production' => 'Lacuna::DB::Building::Water::Production',
    'Lacuna::DB::Building::Water::Purification' => 'Lacuna::DB::Building::Water::Purification',
    'Lacuna::DB::Building::Water::Reclamation' => 'Lacuna::DB::Building::Water::Reclamation',
    'Lacuna::DB::Building::Water::Storage' => 'Lacuna::DB::Building::Water::Storage',
});

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Water));
};

no Moose;
__PACKAGE__->meta->make_immutable;
