package Lacuna::DB::Building::University;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness));
};

use constant controller_class => 'Lacuna::Building::University';

use constant image => 'university';

use constant name => 'University';

use constant food_to_build => 250;

use constant energy_to_build => 450;

use constant ore_to_build => 450;

use constant water_to_build => 100;

use constant waste_to_build => 250;

use constant time_to_build => 600;

use constant food_consumption => 50;

use constant energy_consumption => 50;

use constant ore_consumption => 10;

use constant water_consumption => 50;

use constant waste_production => 50;

use constant happiness_production => 50;

after finish_upgrade => sub {
    my $self = shift;
    my $empire = $self->empire;
    if ($empire->university_level < $self->level) {
        $empire->university_level($self->level);
        $empire->put;
    }
};

no Moose;
__PACKAGE__->meta->make_immutable;
