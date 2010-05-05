package Lacuna::DB::Building::Permanent;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->table('permanent');

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Building::Permanent::Crater' => 'Lacuna::DB::Building::Permanent::Crater',
    'Lacuna::DB::Building::Permanent::GasGiantPlatform' => 'Lacuna::DB::Building::Permanent::GasGiantPlatform',
    'Lacuna::DB::Building::Permanent::Lake' => 'Lacuna::DB::Building::Permanent::Lake',
    'Lacuna::DB::Building::Permanent::RockyOutcrop' => 'Lacuna::DB::Building::Permanent::RockyOutcrop',
    'Lacuna::DB::Building::Permanent::TerraformingPlatform' => 'Lacuna::DB::Building::Permanent::TerraformingPlatform',
});


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
