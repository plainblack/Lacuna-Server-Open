package Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::BlackHoleGenerator';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant image => 'blackholegenerator';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, '%s is experimenting with advanced singularity technology.', $self->body->name);
};

sub can_build_on {
    my $self = shift;

    my $btype = $self->body->get_type;
    unless ($btype eq 'habitable planet') {
        confess [1009, 'Can only be built on habitable planets.'];
    }
    return 1;
}

use constant name => 'Black Hole Generator';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
