package Lacuna::DB::Result::Proposition::ForeignAid;

use Moose;
use utf8;
use DateTime;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);

before pass => sub {
    my ($self) = @_;
    my $resources = $self->scratch->{resources};
    my $planet_id = $self->scratch->{planet_id};
    my $planet = Lacuna->db->resultset('Map::Body')->find($planet_id);
    if (defined $planet) {
        if ($planet->star->station_id == $self->body_id) {
            my @types = qw( energy food ore water );
            my @missing;
            for my $cost ( @types ) {
                my $method = "${cost}_stored";
                unless ( $self->station->$method >= $self->scratch->{"${cost}_cost"} ) {
                    push @missing, $cost;
                }
            }
            if ( !@missing ) {
                $self->station->spend_energy($self->scratch->{energy_cost});
                $self->station->spend_food($self->scratch->{food_cost}, 1);
                $self->station->spend_ore($self->scratch->{ore_cost});
                $self->station->spend_water($self->scratch->{water_cost});
                $self->station->update;
                my $supply_pod = Lacuna->db->resultset('Ships')->new({
                    body_id         => $self->station_id,
                    type            => 'supply_pod',
                    hold_size       => $self->scratch->{resource},
                });
                $supply_pod->date_available(DateTime->now);
                $supply_pod->update;
                $supply_pod->send(target => $planet);
            }
            else {
                $self->pass_extra_message(
                    'Unfortunately by the time the proposition passed, the station did not have enough resources ('.
                    join(', ',@missing).') to build the supply pod, effectively nullifying the vote.');
            }
        }
        else {
            $self->pass_extra_message('Unfortunately by the time the proposition passed, the planet was no longer under the jurisdiction of the station, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately by the time the proposition passed, the planet could not be found, effectively nullifying the vote.');
    }

};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
