package Lacuna::DB::Result::Building::MunitionsLab;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.10);
    if ($planet->uraninite_stored + $planet->monazite_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of radioactive minerals such as Uraninite and Monazite to produce weapons."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::MunitionsLab';

use constant university_prereq => 9;

use constant max_instances_per_planet => 1;

use constant image => 'munitionslab';

use constant name => 'Munitions Lab';

use constant food_to_build => 220;

use constant energy_to_build => 250;

use constant ore_to_build => 250;

use constant water_to_build => 220;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 14;

use constant energy_consumption => 20;

use constant ore_consumption => 50;

use constant water_consumption => 20;

use constant waste_production => 15;

after finish_upgrade => sub {
    my $self = shift;
    my $empire = $self->body->empire;
    if ($empire->is_isolationist) {
        $empire->is_isolationist(0);
        $empire->update;
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
