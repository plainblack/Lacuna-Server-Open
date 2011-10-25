package Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::BlackHoleGenerator';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a Black Hole Generator."];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade a Black Hole Generator. It was left behind by the Great Race."];
};

use constant image => 'blackholegenerator';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('%s is experimenting with advanced singularity technology.', $self->body->name));
};

sub can_build_on {
    my $self = shift;
    unless ($self->body->isa('Lacuna::DB::Result::Map::Body::Planet') &&
            !$self->body->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant')) {
        confess [1009, 'Can only be built on habitable planets.'];
    }
    return 1;
}

use constant name => 'Black Hole Generator';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
