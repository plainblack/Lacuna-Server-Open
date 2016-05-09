package Lacuna::DB::Result::Building::Permanent::Crater;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Crater';

with "Lacuna::Role::Building::CantBuildWithoutPlan";

sub can_upgrade {
    confess [1013, "You can't upgrade a crater. It forms naturally."];
}


sub image {
    my ($self) = @_;
    if (ref $self eq 'Lacuna::DB::Result::Building::Permanent::Crater' && $self->body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        return 'dent';
    }
    return 'crater';
}

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

sub name {
    my ($self) = @_;
    if (ref $self eq 'Lacuna::DB::Result::Building::Permanent::Crater') {
        my $is_station = $self->body->isa('Lacuna::DB::Result::Map::Body::Planet::Station');
        if ($self->is_working) {
            if ($is_station) {
                return 'Smoldering Dent';
            }
            return 'Smoldering Crater';
        }
        elsif ($is_station) {
            return 'Dent';
        }
    }
    return 'Crater';
}

use constant time_to_build => 0;
use constant waste_storage => 500;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
