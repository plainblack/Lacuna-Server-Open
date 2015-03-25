package Lacuna::DB::Result::Building::Permanent::Ravine;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::Ravine';

use constant image => 'ravine';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, 'A tectonic shift shook the inhabitants of %s today as the ground quaked beneath their feet.', $self->body->name);
};

use constant name => 'Ravine';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;
use constant waste_storage => 100_000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
