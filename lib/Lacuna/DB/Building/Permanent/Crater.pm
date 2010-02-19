package Lacuna::DB::Building::Permanent::Crater;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::Crater';
}

has '+image' => ( 
    default => 'crater', 
);

has '+name' => (
    default => 'Crater',
);


no Moose;
__PACKAGE__->meta->make_immutable;
