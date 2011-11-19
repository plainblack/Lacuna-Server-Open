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

    my $status = $self->scratch->pad->{status};
    print "Status is [$status]\n";

    my $scratch = $self->get_colony_scratchpad($colony);
    my $level = $scratch->pad->{level};

    my $quota = {
        peace => {
            5 => [
                ['galleon', 50],
                ['sweeper',350],
            ],
            10 => [
                ['galleon', 50],
                ['sweeper',350],
            ],
            15 => [
                ['galleon', 50],
                ['sweeper',350],
            ],
            20 => [
                ['galleon', 50],
                ['sweeper',350],
            ],
            25 => [
                ['galleon', 50],
                ['sweeper',350],
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
                ['sweeper',                  300],
                ['scow',                     100],
                ['security_ministry_seeker',   5],
                ['snark2',                    10],
            ],
            15 => [
                ['sweeper',                  300],
                ['scow',                     100],
                ['security_ministry_seeker',   5],
                ['snark2',                    10],
            ],
            20 => [
                ['sweeper',                  300],
                ['scow',                     100],
                ['security_ministry_seeker',   5],
                ['snark2',                    10],
            ],
            25 => [
                ['sweeper',                  300],
                ['scow',                     100],
                ['security_ministry_seeker',   5],
                ['snark2',                    10],
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
    $self->build_ships_max($colony);
#    $self->run_missions($colony);
}

sub get_colony_scratchpad {
    my ($self, $colony) = @_;

    my ($scratch) = Lacuna::db->resultset('Lacuna::DB::Result::AIScratchPad')->search({
        ai_empire_id    => $self->empire_id,
        body_id         => $colony->id,
    });

    return $scratch;
}

no Moose;
__PACKAGE__->meta->make_immutable;
