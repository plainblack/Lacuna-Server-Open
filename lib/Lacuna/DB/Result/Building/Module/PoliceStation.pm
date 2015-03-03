package Lacuna::DB::Result::Building::Module::PoliceStation;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';

use constant controller_class => 'Lacuna::RPC::Building::PoliceStation';
use constant image => 'policestation';
use constant name => 'Police Station';
use constant max_instances_per_planet => 1;
use constant food_consumption   => 120;
use constant ore_consumption    => 120;
use constant water_consumption  => 120;
use constant energy_consumption => 120;

sub foreign_spies {
    my $self = shift;
    return Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search({ level => { '<=' => int($self->effective_level * 1.25)},
                   task => { 'not in' => [ 'Captured', 'Prisoner Transport' ] },
                   on_body_id => $self->body_id, empire_id => { '!=' => $self->body->empire_id } });
}

sub prisoners {
    my $self = shift;

    my $dt_parser = Lacuna->db->storage->datetime_parser;
    my $now = $dt_parser->format_datetime( DateTime->now );

    return  Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search(
            {
                on_body_id  => $self->body_id,
                task        => { 'in' => [ 'Captured', 'Prisoner Transport' ] },
                available_on=> { '>' => $now },
            }
        );
}

sub ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
        body_id     => $self->body_id,
    });
}

sub foreign_ships {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {
            foreign_body_id => $self->body_id,
            direction       => 'out',
            task            => 'Travelling',
        }
    );
}

sub orbiting_ships {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {
            foreign_body_id => $self->body_id,
            task            => { in => ['Defend','Orbiting'] },
        }
    );
}

before 'repair' => sub {
    my $self = shift;
    my $db = Lacuna->db;
    my $now = DateTime->now;
    my $dtf = $db->storage->datetime_parser;
    my $i_spies = $db->resultset('Spies')
                    ->search( { on_body_id => $self->body->id,
                                empire_id  => { '!=' => $self->body->empire_id },
                                available_on  => { '<' => $dtf->format_datetime($now) },
                                task => 'Travelling',
                              });
    while (my $spy = $i_spies->next) {
        my $starting_task = $spy->task;
        $spy->is_available;
        if ($spy->task eq 'Idle' && $starting_task ne 'Idle') {
            if (!$spy->empire->skip_spy_recovery) {
                $spy->empire->send_predefined_message(
                    tags        => ['Intelligence'],
                    filename    => 'ready_for_assignment.txt',
                    params      => [$spy->name, $spy->from_body->id, $spy->from_body->name],
                );
            }
        }
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
