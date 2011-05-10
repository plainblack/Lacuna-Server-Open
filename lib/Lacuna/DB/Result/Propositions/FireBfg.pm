package Lacuna::DB::Result::Propositions::FireBfg;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($self->scratch->{body_id});
    if (defined $body && $body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        if (eval {$self->station->in_jurisdiction($body)}) {
            if (defined $body->empire && $body->empire) {
                my $buildings = $body->buildings->search({ class => { in => [
                    'Lacuna::DB::Result::Building::Archaeology',
                    'Lacuna::DB::Result::Building::Development',
                    'Lacuna::DB::Result::Building::Embassy',
                    'Lacuna::DB::Result::Building::EntertainmentDistrict',
                    'Lacuna::DB::Result::Building::Espionage',
                    'Lacuna::DB::Result::Building::GasGiantLab',
                    'Lacuna::DB::Result::Building::GeneticsLab',
                    'Lacuna::DB::Result::Building::Intelligence',
                    'Lacuna::DB::Result::Building::Network19',
                    'Lacuna::DB::Result::Building::Observatory',
                    'Lacuna::DB::Result::Building::Oversight',
                    'Lacuna::DB::Result::Building::Park',
                    'Lacuna::DB::Result::Building::Propulsion',
                    'Lacuna::DB::Result::Building::Security',
                    'Lacuna::DB::Result::Building::Shipyard',
                    'Lacuna::DB::Result::Building::SpacePort',
                    'Lacuna::DB::Result::Building::TerraformingLab',
                    'Lacuna::DB::Result::Building::Trade',
                    'Lacuna::DB::Result::Building::Transporter',
                    'Lacuna::DB::Result::Building::University',
                    'Lacuna::DB::Result::Building::Waste::Recycling',
                    'Lacuna::DB::Result::Building::Waste::Sequestration',
                    ] }});
                while (my $building = $buildings->next) {
                    $building->efficiency(0);
                    $building->update;
                }
                $body->needs_recalc(1);
                $body->needs_surface_refresh(1);
                $body->update;
                $body->add_news(99, sprintf('The parliament of %s has fired their BFG at %s, devastating the surface.', $self->station->name, $body->name));
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
