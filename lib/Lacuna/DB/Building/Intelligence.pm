package Lacuna::DB::Building::Intelligence;

use Moose;
extends 'Lacuna::DB::Building';

#__PACKAGE__->add_attributes(
#    spies           => { isa => 'Int' },
#    counter_spies   => { isa => 'Int' },
#);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence));
};

use constant controller_class => 'Lacuna::Building::Intelligence';

use constant max_instances_per_planet => 1;

use constant university_prereq => 2;

use constant image => 'intelligence';

use constant name => 'Intelligence Ministry';

use constant food_to_build => 83;

use constant energy_to_build => 82;

use constant ore_to_build => 82;

use constant water_to_build => 83;

use constant waste_to_build => 70;

use constant time_to_build => 300;

use constant food_consumption => 7;

use constant energy_consumption => 10;

use constant ore_consumption => 2;

use constant water_consumption => 7;

use constant waste_production => 1;

sub add_counter_spy {
    my ($self, $count) = @_;
    # do this later
    return $self;
}

sub count_counter_spies {
    return 0;
}


no Moose;
__PACKAGE__->meta->make_immutable;
