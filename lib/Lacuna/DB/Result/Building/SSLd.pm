package Lacuna::DB::Result::Building::SSLd;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Construction Ships));
};

# use constant building_prereq => {'Lacuna::DB::Result::Building::SSLc'=>1};
use constant max_instances_per_planet => 1;

use constant controller_class => 'Lacuna::RPC::Building::SSLd';

use constant image => 'ssld';

use constant name => 'Space Station Lab (D)';

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

before can_build => sub {
    my $self = shift;
    my $sslc = $self->body->get_building_of_class('Lacuna::DB::Result::Building::SSLc');
    unless (defined $sslc) {
        confess [1013, 'You must have a Space Station Lab (C) before you can build Space Station Lab (D).'];
    }
    unless ($self->x == $sslc->x - 1 && $self->y == $sslc->y) {
        confess [1013, 'Space Station Lab (D) must be placed to the left of Space Station Lab (C).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
