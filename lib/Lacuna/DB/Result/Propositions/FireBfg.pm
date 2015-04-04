package Lacuna::DB::Result::Propositions::FireBfg;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $body    = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($self->scratch->{body_id});
    my $station = $self->station;
    my $parl    = $station->parliament;

    if (defined $body && $body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        if (eval {$self->station->in_jurisdiction($body)}) {
            my $costs = {
                food   => 1e6,
                energy => 10e6,
                ore    => 100e6,
                water  => 10e6,
            };
            if (eval { $station->has_resources_to_build($parl, $costs); 1})
            {
                $station->spend_food($costs->{food}, 0);
                $station->spend_water($costs->{water});
                $station->spend_ore($costs->{ore});
                $station->spend_energy($costs->{energy});
                $station->needs_recalc(1);
                $station->update;

                if (defined $body->empire_id && $body->empire_id) {
                    foreach my $building (@{$body->building_cache}) {
                        next unless ('Infrastructure' ~~ [$building->build_tags]);
                        next if ( $building->class eq 'Lacuna::DB::Result::Building::PlanetaryCommand' );
                        $building->efficiency(0);
                        $building->update;
                    }
                    $body->needs_recalc(1);
                    $body->needs_surface_refresh(1);
                    $body->update;
                    $body->add_news(99, 'The parliament of %s has fired their BFG at %s, devastating the surface.', $self->station->name, $body->name);
                    $body->empire->send_message(
                        subject     => 'BFG Damage',
                        body        => "The parliament of ".$self->station->name." has fired their BFG at ".$body->name.". The planet has been devastated, and I doubt it's repairable.\n\nRegards,\n\nYour Humble Assistant",
                        tag         => 'Alert',
                    );
                } 
                else {
                    $self->pass_extra_message('Unfortunately, by the time the proposition passed, the planet was no longer occupied.');
                }
            }
            elsif ($parl) {
                # to ensure it can be downgraded by this.
                $parl->is_upgrading(0);
                $parl->downgrade(1); # no point producing waste/unhappy
                if ($parl->level >= 1)
                {
                    $parl->spend_efficiency(25);
                    $parl->update;
                    $self->station->add_news(49, 'The parliament of %s suffered a malfunction today while trying to fire their BFG.', $self->station->name);
                }
                else
                {
                    $self->station->add_news(99, 'The parliament of %s suffered a critical malfunction today while trying to fire their BFG.', $self->station->name);
                }
                $self->station->update;

                $self->pass_extra_message('Unfortunately, by the time the proposition passed, the station no longer had sufficient resources to fire with and suffered major damage.');
            }
            else {
                $self->pass_extra_message('Unfortunately, by the time the proposition passed, there was no parliament to enact it.');
            }
        }
        else {
            $self->pass_extra_message('Unfortunately, by the time the proposition passed, the planet was no longer in the Station\'s jurisdiction, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the planet no longer existed, effectively nullifying the vote.');
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
