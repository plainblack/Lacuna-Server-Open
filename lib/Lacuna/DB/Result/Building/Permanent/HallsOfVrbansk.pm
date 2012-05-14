package Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk;

use Moose;
use utf8;
use List::Util qw(min);

no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::HallsOfVrbansk';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build the Halls of Vrbansk."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade the Halls of Vrbansk."];
}

use constant image => 'hallsofvrbansk';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('The ancient wisdom of the Great Race is still alive on %s.', $self->body->name));
};

sub get_halls {
    my $self = shift;
    return $self->body->get_buildings_of_class('Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk')->search({
        is_upgrading => 0,
    });
}

sub get_upgradable_buildings {
    my ($self) = @_;
    my $body    = $self->body;
    $body->update;
    # The max_level is represented by the number of halls already
    # built, plus the minimum of the number of free building spaces or
    # the number of hall plans
    my $halls = $self->get_halls->count;
    my $plans = Lacuna->db->resultset('Plans')->search({
        body_id => $body->id,
        class => 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk',
    })->count;
    my $buildings = Lacuna->db->resultset('Building')->search({
        body_id => $body->id,
    })->count;
    my $max_level = $halls + min(( 121 - $buildings), $plans);
    $max_level = 30 if $max_level > 30;

    my $rs = $body->buildings->search({
        level   => { '<' => $max_level },
        -and    => [
            class => {like => 'Lacuna::DB::Result::Building::Permanent::%'},
            class => {'!=' => 'Lacuna::DB::Result::Building::Permanent::TheDillonForge'},
            class => {'!=' => 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk'},
        ],
        is_upgrading    => 0,
    });
    return $rs;
}

use constant name => 'Halls of Vrbansk';
use constant time_to_build => 0;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
