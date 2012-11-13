package Lacuna::DB::Result::Building::SSLc;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Construction Ships));
};

# use constant building_prereq => {'Lacuna::DB::Result::Building::SSLb'=>1};
use constant max_instances_per_planet => 1;

use constant controller_class => 'Lacuna::RPC::Building::SSLc';

use constant image => 'sslc';

use constant name => 'Space Station Lab (C)';

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
    my $ssld = $self->body->get_building_of_class('Lacuna::DB::Result::Building::SSLd');
    if (defined $ssld) {
        confess [1013, 'You have to demolish your Space Station Lab (D) before you can demolish your Space Station Lab (C).'];
    }
};

before can_build => sub {
    my $self = shift;
    my $sslb = $self->body->get_building_of_class('Lacuna::DB::Result::Building::SSLb');
    unless (defined $sslb) {
        confess [1013, 'You must have a Space Station Lab (B) before you can build Space Station Lab (C).'];
    }
    unless ($self->x == $sslb->x && $self->y == $sslb->y - 1) {
        confess [1013, 'Space Station Lab (C) must be placed below Space Station Lab (B).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
