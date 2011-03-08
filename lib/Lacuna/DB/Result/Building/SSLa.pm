package Lacuna::DB::Result::Building::SSLa;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Construction Ships));
};

use constant university_prereq => 20;
use constant max_instances_per_planet => 1;

use constant controller_class => 'Lacuna::RPC::Building::SSLa';

use constant image => 'ssla';

use constant name => 'Space Station Lab (A)';

use constant food_to_build => 230;

use constant energy_to_build => 350;

use constant ore_to_build => 370;

use constant water_to_build => 260;

use constant waste_to_build => 100;

use constant time_to_build => 60 * 2;

use constant food_consumption => 5;

use constant energy_consumption => 20;

use constant ore_consumption => 15;

use constant water_consumption => 6;

use constant waste_production => 20;


before 'can_demolish' => sub {
    my $self = shift;
    my $sslb = $self->body->get_building_of_class('Lacuna::DB::Result::Building::SSLb');
    if (defined $sslb) {
        confess [1013, 'You have to demolish your Space Station Lab (B) before you can demolish your Space Station Lab (A).'];
    }
};

before can_build => sub {
    my $self = shift;
    if ($self->x == 5 || $self->y == 5 || (($self->y == 1 || $self->y == 0) && ($self->x == -1 || $self->x == 0))) {
        confess [1009, 'Space Station Lab cannot be placed in that location.'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
