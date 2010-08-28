package Lacuna::DB::Result::Building::Stockpile;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Storage Food Water Ore Energy));
};

use constant building_prereq => {'Lacuna::DB::Result::Building::Capitol'=>10};

use constant controller_class => 'Lacuna::RPC::Building::Stockpile';

use constant image => 'stockpile';

use constant name => 'Stockpile';

use constant food_to_build => 330;

use constant energy_to_build => 330;

use constant ore_to_build => 330;

use constant water_to_build => 330;

use constant waste_to_build => 100;

use constant time_to_build => 230;

use constant food_consumption => 2;

use constant energy_consumption => 5;

use constant ore_consumption => 1;

use constant water_consumption => 2;

use constant waste_production => 1;

use constant food_storage => 300;

use constant energy_storage => 300;

use constant ore_storage => 300;

use constant water_storage => 300;

before 'can_downgrade' => sub {
    my $self = shift;
    my $buildings = $self->body->buildings;
    while (my $building = $buildings->next) {
        if ($building->level > 15 && 'Resources' ~~ [$building->build_tags] && !('Storage' ~~ [$building->build_tags])) {
            confess [1013, 'You have to downgrade your level '.$building->level.' '.$building->name.' to level 15 before you can downgrade the Stockpile.'];
        }
    }
};

before 'can_demolish' => sub {
    my $self = shift;
    my $buildings = $self->body->buildings;
    while (my $building = $buildings->next) {
        if ($building->level > 15 && 'Resources' ~~ [$building->build_tags] && !('Storage' ~~ [$building->build_tags])) {
            confess [1013, 'You have to downgrade your level '.$building->level.' '.$building->name.' to level 15 before you can demolish the Stockpile.'];
        }
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
