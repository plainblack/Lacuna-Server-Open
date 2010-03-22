package Lacuna::DB::Building::Water::Purification;

use Moose;
extends 'Lacuna::DB::Building::Water';

use constant controller_class => 'Lacuna::Building::WaterPurification';

use constant image => 'waterpurification';

use constant name => 'Water Purification Plant';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 850;

use constant food_consumption => 5;

use constant energy_consumption => 15;

use constant ore_consumption => 15;

use constant water_production => 100;

sub water_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->body->water * $self->water_production * $self->production_hour / 10000);
}

use constant waste_production => 10;



no Moose;
__PACKAGE__->meta->make_immutable;
