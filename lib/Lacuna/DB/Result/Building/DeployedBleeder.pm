package Lacuna::DB::Result::Building::DeployedBleeder;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

use constant controller_class => 'Lacuna::RPC::Building::DeployedBleeder';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"If you want a Bleeder, build one at the Shipyard."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade a Deployed Bleeder."];
}

use constant image => 'deployedbleeder';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Deployed Bleeder';
use constant time_to_build => 15;

after finish_upgrade => sub {
    my $self = shift;
    $self->discard_changes;

    if ($self->level < 30) {
        $self->start_upgrade(undef, 1);
    }
};

use constant food_consumption => 125;
use constant energy_consumption => 125;
use constant ore_consumption => 125;
use constant water_consumption => 125;
use constant waste_production => 500;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
