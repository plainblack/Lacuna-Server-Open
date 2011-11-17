package Lacuna::AI::DeLambert;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Data::Dumper;

extends 'Lacuna::AI';

use constant empire_id  => -9;

sub spy_missions {
    return (
        'Appropriate Resources',
    );
}

sub ship_building_priorities {
    my ($self, $colony) = @_;

    my $status = 'peace';
    my ($dillon_forge)  = $colony->get_buildings_of_class('Lacuna::DB::Result::Building::Permanent::TheDillonForge');
    my $level = $dillon_forge ? $dillon_forge->level : 0;

    my $quota = {
        peace => {
            5 => [
                ['galleon', 50],
                ['sweeper',350],
            ],
            10 => [
            ],
            15 => [
            ],
            20 => [
            ],
            25 => [
            ],
            30 => [
                ['galleon', 50],
                ['sweeper',350],
            ],
        },
        war => {
            5 => [
                ['sweeper',                  300],
                ['scow',                     100],
                ['security_ministry_seeker',   5],
                ['snark2',                    10],
            ],
            10 => [
            ],
            15 => [
            ],
            20 => [
            ],
            25 => [
            ],
            30 => [
                ['sweeper',                  300],
                ['scow',                     100],
                ['security_ministry_seeker',   5],
                ['snark2',                    10],
            ],
        },
    };

    return ( @{$quota->{$status}{$level}} );
}

sub run_hourly_colony_updates {
    my ($self, $colony) = @_;
#    $self->demolish_bleeders($colony);
#    $self->set_defenders($colony);
#    $self->repair_buildings($colony);
#    $self->train_spies($colony);
    $self->build_ships($colony);
#    $self->run_missions($colony);
}

no Moose;
__PACKAGE__->meta->make_immutable;
