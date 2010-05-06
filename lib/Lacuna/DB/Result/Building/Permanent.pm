package Lacuna::DB::Result::Building::Permanent;

use Moose;
extends 'Lacuna::DB::Result::Building';

__PACKAGE__->load_components('DynamicSubclass');

__PACKAGE__->table('permanent');

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Result::Building::Permanent::Crater' => 'Lacuna::DB::Result::Building::Permanent::Crater',
    'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform' => 'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform',
    'Lacuna::DB::Result::Building::Permanent::Lake' => 'Lacuna::DB::Result::Building::Permanent::Lake',
    'Lacuna::DB::Result::Building::Permanent::RockyOutcrop' => 'Lacuna::DB::Result::Building::Permanent::RockyOutcrop',
    'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform' => 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',
});


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
