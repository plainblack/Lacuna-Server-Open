package Lacuna::DB::Result::Building::Permanent::GeoThermalVent;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::GeoThermalVent';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a Geo Thermal Vent. It forms naturally."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade a Geo Thermal Vent. It forms naturally."];
}

use constant image => 'geothermalvent';

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('%s considers itself a very efficient planet, much of its energy production coming from thermal vents.', $self->body->name));
};

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Geo Thermal Vent';
use constant energy_production => 4000;
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
