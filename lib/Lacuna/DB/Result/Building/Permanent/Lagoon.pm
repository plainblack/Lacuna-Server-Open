package Lacuna::DB::Result::Building::Permanent::Lagoon;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Lagoon';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a lagoon. It forms naturally."];
};

use constant image => 'lagoon';

use constant name => 'Lagoon';

use constant water_to_build => 1;
use constant ore_to_build => 1;
use constant time_to_build => 1;
use constant algae_production => 0.2; 
around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(algae);
    return $foods;
};
use constant water_production => 0.1;
use constant max_instances_per_planet => 1;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
