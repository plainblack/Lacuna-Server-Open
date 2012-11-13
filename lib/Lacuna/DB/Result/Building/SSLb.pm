package Lacuna::DB::Result::Building::SSLb;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Construction Ships));
};

# use constant building_prereq => {'Lacuna::DB::Result::Building::SSLa'=>1};
use constant max_instances_per_planet => 1;

use constant controller_class => 'Lacuna::RPC::Building::SSLb';

use constant image => 'sslb';

use constant name => 'Space Station Lab (B)';

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
    my $sslc = $self->body->get_building_of_class('Lacuna::DB::Result::Building::SSLc');
    if (defined $sslc) {
        confess [1013, 'You have to demolish your Space Station Lab (C) before you can demolish your Space Station Lab (B).'];
    }
};

before can_build => sub {
    my $self = shift;
    my $ssla = $self->body->get_building_of_class('Lacuna::DB::Result::Building::SSLa');
    unless (defined $ssla) {
        confess [1013, 'You must have a Space Station Lab (A) before you can build Space Station Lab (B).'];
    }
    unless ($self->x == $ssla->x + 1 && $self->y == $ssla->y) {
        confess [1013, 'Space Station Lab (B) must be placed to the right of Space Station Lab (A).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
