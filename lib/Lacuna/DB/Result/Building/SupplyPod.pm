package Lacuna::DB::Result::Building::SupplyPod;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES GROWTH);

use constant controller_class => 'Lacuna::RPC::Building::SupplyPod';

with 'Lacuna::Role::Building::IgnoresUniversityLevel';

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

sub finish_upgrade_news
{
    my ($self, $new_level, $empire) = @_;
    if ($new_level % 5 == 0) {
        my %levels = (5=>'a small',10=>'a',15=>'a large',20=>'a huge',25=>'a gigantic',30=>'a Tardis-branded');
        $self->body->add_news($new_level*4,"The citizens of %s cheered as %s supply pod full of supplies survived a crash landing today.", $empire->name, $levels{$new_level});
    }
}

after finish_work => sub {
    my $self = shift;
    my $body = $self->body;
    $body->needs_surface_refresh(1);
    $body->needs_recalc(1);
    $body->update;
    $self->update({class=>'Lacuna::DB::Result::Building::Permanent::Crater'});
};

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
