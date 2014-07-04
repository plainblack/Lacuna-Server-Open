package Lacuna::DB::Result::Proposition::FireBfg;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $body = Lacuna->db->resultset('Map::Body')->find($self->scratch->{body_id});
    if (defined $body && $body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        if (not $body->star->is_seized($self->alliance_id)) {
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
                $body->add_news(99, sprintf('The alliance of %s has fired their BFG at %s, devastating the surface.', $self->alliance->name, $body->name));
                $body->empire->send_message(
                    subject     => 'BFG Damage',
                    body        => "The alliance of ".$self->alliance->name." has fired their BFG at ".$body->name.". The planet has been devastated, and I doubt it's repairable.\n\nRegards,\n\nYour Humble Assistant",
                    tag         => 'Alert',
                );
            }
            else {
                $self->pass_extra_message('Unfortunately, by the time the proposition passed, the planet was no longer occupied.');
            }
        }
        else {
            $self->pass_extra_message('Unfortunately, by the time the proposition passed, the planet was no longer in the alliance\'s jurisdiction, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the planet no longer existed, effectively nullifying the vote.');
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
