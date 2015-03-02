package Lacuna::DB::Result::Building::SupplyPod;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES GROWTH);

use constant controller_class => 'Lacuna::RPC::Building::SupplyPod';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a Supply Pod."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade a Supply Pod."];
}

use constant image => 'supply_pod';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Supply Pod';

use constant time_to_build => 0;

after finish_upgrade => sub {
    my $self = shift;
    $self->start_work({}, 60 * 60 * 24)->update;
};

after finish_work => sub {
    my $self = shift;
    my $body = $self->body;
    $body->needs_surface_refresh(1);
    $body->needs_recalc(1);
    $body->update;
    $self->update({class=>'Lacuna::DB::Result::Building::Permanent::Crater'});
};

sub production_hour {
    my $self = shift;
    return 0 unless  $self->level;
    my $prod_level = $self->level;
    my $production = (GROWTH ** (  $prod_level - 1));
    $production = ($production * $self->efficiency) / 100;
    return $production;
}

# allow demolishing even when working
sub can_demolish {
    return 1;
}

use constant food_storage => 2000;
use constant energy_storage => 2000;
use constant ore_storage => 2000;
use constant water_storage => 2000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
