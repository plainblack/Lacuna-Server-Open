package Lacuna::DB::Building::Network19;

use Moose;
extends 'Lacuna::DB::Building';
use Lacuna::Util qw(to_seconds);
use DateTime;

__PACKAGE__->add_attributes(
    restrict_coverage           => { isa=>'Str', default => 0 },  
    restrict_coverage_delta     => { isa=>'DateTime' },  
);

sub restrict_coverage_delta_in_seconds {
    my $self = shift;
    return to_seconds(DateTime->now - $self->restrict_coverage_delta);
}

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness Intelligence));
};

use constant controller_class => 'Lacuna::Building::Network19';

use constant university_prereq => 2;

use constant max_instances_per_planet => 1;

use constant image => 'network19';

use constant name => 'Network 19 Affiliate';

use constant food_to_build => 98;

use constant energy_to_build => 98;

use constant ore_to_build => 100;

use constant water_to_build => 98;

use constant waste_to_build => 60;

use constant time_to_build => 300;

use constant food_consumption => 6;

use constant energy_consumption => 19;

use constant ore_consumption => 1;

use constant water_consumption => 8;

use constant waste_production => 3;

use constant happiness_production => 30;

sub happiness_consumption {
    my ($self) = @_;
    return ($self->restrict_coverage) ? 20 : 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;
