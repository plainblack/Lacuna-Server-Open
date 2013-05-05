package Lacuna::DB::Result::Building::SubspaceSupplyDepot;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

use constant controller_class => 'Lacuna::RPC::Building::SubspaceSupplyDepot';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a Subspace Supply Depot. You have to be given one from Lacuna Expanse Corp."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade a Subspace Supply Depot. You have to be given one from Lacuna Expanse Corp."];
}

use constant image => 'subspacesupplydepot';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Subspace Supply Depot';

use constant time_to_build => 0;

after finish_upgrade => sub {
    my ($self) = @_;

    $self->start_work({}, 60 * 60 * 24 * 5)->update;
    $self->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'subspace_supply_depot.txt',
        params      => [$self->body->name, randint(1000,10000000), randint(1000,10000000), randint(1000,10000000), randint(1000,10000000)],
        from        => $self->body->empire->lacuna_expanse_corp,
    );
};

sub transmit_food {
    my ($self) = @_;

    if ($self->work_ends->epoch - time  <= 3600 ) {
        confess [1011, 'Not enough energy remaining to transmit resources.']
    }
    my $new_work_ends = $self->work_ends->subtract(seconds => 3600);
    $self->reschedule_work($new_work_ends);

    my @types = (FOOD_TYPES);
    $self->body->add_type($types[ rand @types ], 3600)->update;
}

sub transmit_ore {
    my ($self) = @_;

    unless ($self->work_ends->epoch - time  > 3600 ) {
        confess [1011, 'Not enough energy remaining to transmit resources.']
    }
    my $new_work_ends = $self->work_ends->subtract(seconds => 3600);
    $self->reschedule_work($new_work_ends);

    my @types = (ORE_TYPES);
    $self->body->add_type($types[ rand @types ], 3600)->update;
}

sub transmit_water {
    my ($self) = @_;

    unless ($self->work_ends->epoch - time  > 3600 ) {
        confess [1011, 'Not enough energy remaining to transmit resources.']
    }
    my $new_work_ends = $self->work_ends->subtract(seconds => 3600);
    $self->reschedule_work($new_work_ends);

    $self->body->add_type('water', 3600)->update;
}

sub transmit_energy {
    my ($self) = @_;

    unless ($self->work_ends->epoch - time  > 3600 ) {
        confess [1011, 'Not enough energy remaining to transmit resources.']
    }
    my $new_work_ends = $self->work_ends->subtract(seconds => 3600);
    $self->reschedule_work($new_work_ends);

    $self->body->add_type('energy', 3600)->update;
}

sub complete_build_queue {
    my ($self) = @_;

    my $time_to_complete = $self->body->get_existing_build_queue_time->epoch - time;
    if ($time_to_complete > $self->work_ends->epoch - time) {
        confess [1011, 'Not enough time remaining to complete the build queue.'];
    }
    my $new_work_ends = $self->work_ends->subtract(seconds => $time_to_complete);
    $self->reschedule_work($new_work_ends);

    foreach my $build (@{$self->body->builds}) {
        $build->finish_upgrade;
    }
}

after finish_work => sub {
    my ($self) = @_;

    my $body = $self->body;
    $body->needs_surface_refresh(1);
    $body->needs_recalc(1);
    $body->update;
    if (defined $body->spaceport) {
        $body->ships->new({
            body_id => $body->id,
            type    => 'short_range_colony_ship',
            name    => 'The Gift',
            speed   => 5500,
            task    => 'Docked',
        })->insert;
        $body->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'subspace_supply_depot_srcs.txt',
            params      => [$body->name, randint(1000,10000000), randint(1000,10000000), randint(1000,10000000), randint(1000,10000000)],
            from        => $body->empire->lacuna_expanse_corp,
        );
    }
    $self->update({class=>'Lacuna::DB::Result::Building::Permanent::Crater'});
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
