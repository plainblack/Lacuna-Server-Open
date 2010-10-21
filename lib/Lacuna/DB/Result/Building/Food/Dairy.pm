package Lacuna::DB::Result::Building::Food::Dairy;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::Dairy';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Corn'=>5};

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.05);
    if ($planet->trona_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of Trona to produce milk from cows."];
    }
};


use constant min_orbit => 3;

use constant max_orbit => 3;

use constant image => 'dairy';

use constant name => 'Dairy Farm';

use constant food_to_build => 200;

use constant energy_to_build => 100;

use constant ore_to_build => 150;

use constant water_to_build => 200;

use constant waste_to_build => 50;

use constant time_to_build => 110;

use constant food_consumption => 8;

use constant milk_production => 68;

use constant energy_consumption => 6;

use constant ore_consumption => 1;

use constant water_consumption => 10;

use constant waste_production => 33;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(milk);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
