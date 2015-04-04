package Lacuna::DB::Result::Building::Capitol;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness Intelligence));
};

use constant building_prereq => {'Lacuna::DB::Result::Building::PlanetaryCommand'=>10};

use constant max_instances_per_planet => 1;

use constant controller_class => 'Lacuna::RPC::Building::Capitol';

use constant image => 'capitol';

use constant name => 'Capitol';

use constant food_to_build => 350;

use constant energy_to_build => 350;

use constant ore_to_build => 350;

use constant water_to_build => 350;

use constant waste_to_build => 100;

use constant time_to_build => 230;

use constant food_consumption => 18;

use constant energy_consumption => 13;

use constant ore_consumption => 2;

use constant water_consumption => 20;

use constant waste_production => 5;

use constant happiness_production => 15;

before 'can_demolish' => sub {
    my $self = shift;
    my $stockpile = $self->body->get_building_of_class('Lacuna::DB::Result::Building::Stockpile');
    if (defined $stockpile) {
        confess [1013, 'You have to demolish your Stockpile before you can demolish your Capitol.'];
    }
};

before 'can_downgrade' => sub {
    my $self = shift;
    my $stockpile = $self->body->get_building_of_class('Lacuna::DB::Result::Building::Stockpile');
    if (defined $stockpile and $self->level < 11) {
        confess [1013, 'You have to demolish your Stockpile before you can downgrade your Capitol lower than level 10.'];
    }
};

before can_build => sub {
    my $self = shift;
    my @ids = $self->body->empire->planets->get_column('id')->all;
    my $count = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({ class => __PACKAGE__, body_id => { in => \@ids } })->count;
    if ($count) {
        confess [1013, 'You can only have one Capitol.'];
    }
};

after finish_upgrade => sub {
    my $self = shift;
    my $body = $self->body;
    my $empire = $body->empire;
    $empire->home_planet_id($body->id);
    $empire->update;
    $body->add_news(80, '%s have announced that their new capitol is %s.', $empire->name, $body->name);
};

sub rename_empire_cost {
    my $self = shift;
    return 30 - $self->effective_level;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
