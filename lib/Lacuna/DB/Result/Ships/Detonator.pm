package Lacuna::DB::Result::Ships::Detonator;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant prereq         => { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 1 };
use constant base_food_cost      => 6000;
use constant base_water_cost     => 15600;
use constant base_energy_cost    => 113600;
use constant base_ore_cost       => 97200;
use constant base_time_cost      => 86400;
use constant base_waste_cost     => 25200;
use constant base_speed     => 1000;
use constant base_stealth   => 2000;
use constant base_hold_size => 0;


sub arrive {
    my ($self) = @_;
    my $probes = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({star_id => $self->foreign_star_id });
    my $count;
    while (my $probe = $probes->next) {
        $probe->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'probe_detonated.txt',
            params      => [$self->foreign_star->name, $self->body->empire_id, $self->body->empire->name],
        );
        $count++;
    }
    $self->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'detonator_destroyed_probes.txt',
        params      => [$count, $self->foreign_star->name],
    );
    $self->delete;
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to stars.'] unless ($target->isa('Lacuna::DB::Result::Map::Star'));
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
