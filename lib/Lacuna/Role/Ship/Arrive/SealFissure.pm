package Lacuna::Role::Ship::Arrive::SealFissure;

use strict;
use Moose::Role;
use Lacuna::Util qw(randint);
use DateTime;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

    # Turn around if occupied
    return if ($self->foreign_body->empire_id);

    # determine target building
    my $building;
    my $body_hit = $self->foreign_body;
    my ($fissure) = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::Fissure'} @{$body_hit->building_cache};
    return if not defined $fissure;
    
    $body_hit->add_news(70, sprintf('An attempt to fix the fissure on %s happened today.', $body_hit->name));

    # handle fissure
    if (defined $fissure) {
        my $curr_eff = $fissure->efficiency + randint(1,7);
        $curr_eff = 100 if $curr_eff > 100;
        $curr_lev = $fissure->level;

        if ( int(5.5 + $curr_eff/10) > randint(0,99) ) {
            $curr_lev--;
        }
        if ($curr_lev < 1) {
            $fissure->delete;
        }
        else {
            $fissure->level($curr_lev);
            $fissure->efficiency($curr_eff);
            $fissure->update;
        }
        $self->body->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'our_ship_hit_fissure.txt',
            params      => [$self->type_formatted, $body_hit->x, $body_hit->y, $body_hit->name, $curr_lev, $curr_eff ],
        );
        $self->delete;
        $body_hit->needs_surface_refresh(1);
        $body_hit->update;
    }
    
    confess [-1];
};

1;
