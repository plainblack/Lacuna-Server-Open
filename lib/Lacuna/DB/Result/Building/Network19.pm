package Lacuna::DB::Result::Building::Network19;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness Intelligence));
};

use constant controller_class => 'Lacuna::RPC::Building::Network19';

use constant university_prereq => 2;

use constant max_instances_per_planet => 1;

use constant image => 'network19';

use constant name => 'Network 19 Affiliate';

use constant food_to_build => 98;

use constant energy_to_build => 98;

use constant ore_to_build => 100;

use constant water_to_build => 98;

use constant waste_to_build => 60;

use constant time_to_build => 150;

use constant food_consumption => 6;

use constant energy_consumption => 19;

use constant ore_consumption => 1;

use constant water_consumption => 8;

use constant waste_production => 3;

use constant happiness_production => 20;

sub happiness_consumption {
    my ($self) = @_;
    return ($self->body->restrict_coverage) ? 30 : 0;
}

before delete => sub {
    my ($self) = @_;
    $self->body->restrict_coverage(0);
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
