package Lacuna::DB::Building::Security;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence));
};

use constant controller_class => 'Lacuna::Building::Security';

use constant max_instances_per_planet => 1;

use constant building_prereq => {'Lacuna::DB::Building::Intelligence'=>1};

use constant image => 'security';

use constant name => 'Security Ministry';

use constant food_to_build => 90;

use constant energy_to_build => 100;

use constant ore_to_build => 120;

use constant water_to_build => 90;

use constant waste_to_build => 70;

use constant time_to_build => 300;

use constant food_consumption => 5;

use constant energy_consumption => 10;

use constant ore_consumption => 2;

use constant water_consumption => 7;

use constant waste_production => 5;

use constant happiness_consumption => 10;

after finish_upgrade => sub {
    my $self = shift;
    my $defense = $self->level + $self->empire->species->deception_affinity;
    $self->simpledb->domain('spies')->search(where => {from_body_id => $self->body_id})->update({defense=>$defense});
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
