package Lacuna::DB::Result::Building::Capitol;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness Intelligence));
};

use constant building_prereq => {'Lacuna::DB::Result::Building::PlanetaryCommand'=>10};

use constant controller_class => 'Lacuna::RPC::Building::Capitol';

use constant image => 'capitol';

use constant name => 'Capitol';

use constant food_to_build => 350;

use constant energy_to_build => 350;

use constant ore_to_build => 350;

use constant water_to_build => 350;

use constant waste_to_build => 100;

use constant time_to_build => 230;

use constant food_consumption => 18;

use constant energy_consumption => 13;

use constant ore_consumption => 2;

use constant water_consumption => 20;

use constant waste_production => 5;

use constant happiness_production => 15;

before 'can_demolish' => sub {
    my $self = shift;
    my $stockpile = $self->body->get_building_of_class('Lacuna::DB::Result::Building::Stockpile');
    if (defined $stockpile) {
        confess [1013, 'You have to demolish your Stockpile before you can demolish your Capitol.'];
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
