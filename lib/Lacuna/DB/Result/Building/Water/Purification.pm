package Lacuna::DB::Result::Building::Water::Purification;

use Moose;
extends 'Lacuna::DB::Result::Building::Water';

use constant controller_class => 'Lacuna::RPC::Building::WaterPurification';

use constant image => 'waterpurification';

use constant name => 'Water Purification Plant';

use constant food_to_build => 90;

use constant energy_to_build => 80;

use constant ore_to_build => 110;

use constant water_to_build => 10;

use constant waste_to_build => 20;

use constant time_to_build => 100;

use constant food_consumption => 1;

use constant energy_consumption => 3;

use constant ore_consumption => 3;

use constant water_consumption => 2;

use constant water_production => 40;

use constant waste_production => 5;

sub water_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->body->water * $self->water_production * $self->production_hour / 10000);
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
