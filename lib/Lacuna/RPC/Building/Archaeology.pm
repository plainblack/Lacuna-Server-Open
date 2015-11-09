package Lacuna::RPC::Building::Archaeology;

use Lacuna::Util qw(format_date);
use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/archaeology';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Archaeology';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    if ($building->is_working) {
        $out->{building}{work}{searching} = $building->work->{ore_type};
    }
    return $out;
};

sub get_glyphs {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my @out;
    my $glyphs = $building->body->glyph;
    while (my $glyph = $glyphs->next) {
        push @out, {
            id      => $glyph->id,
            name    => $glyph->type,
            type    => $glyph->type,
            quantity => $glyph->quantity,
        };
    }
    return {
        glyphs  => \@out,
        status  => $self->format_status($empire, $building->body),
    };
}

sub get_glyph_summary {
    my ($self, $session_id, $building_id) = @_;

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my @out;
    my $glyphs = $building->body->glyph;
    while (my $glyph = $glyphs->next) {
        push @out, {
            id      => $glyph->id,
            name    => $glyph->type,
            type    => $glyph->type,
            quantity => $glyph->quantity,
        };
    }

    return {
        glyphs  => \@out,
        status  => $self->format_status($empire, $building->body),
    };
}

sub get_ores_available_for_processing {
    my ($self, $session_id, $building_id, $ore) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    return {
        ore                 => $building->get_ores_available_for_processing,
        status              => $self->format_status($empire, $building->body),
    };
}

sub search_for_glyph {
    my ($self, $session_id, $building_id, $ore) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $building->search_for_glyph($ore);
    return $self->view($session, $building);
}

sub assemble_glyphs {
    my ($self, $session_id, $building_id, $glyphs, $quantity) = @_;
    $quantity = defined $quantity ? $quantity : 1;
    if ($quantity > 5000) {
        confess [1011, "You can only assemble up to 5000 plans at a time"];
    }
    if ($quantity <= 0 or int($quantity) != $quantity) {
        confess [1001, "Quantity must be a positive integer"];
    }

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $plan = $building->make_plan($glyphs, $quantity);
    return {
        item_name           => $plan->class->name,
        quantity            => $quantity,
        status              => $self->format_status($empire, $building->body),
    };
}



sub subsidize_search {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    unless ($building->is_working) {
        confess [1010, "No one is searching."];
    }
 
    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];    
    }

    $building->finish_work->update;
    $empire->spend_essentia({
        amount      => 2, 
        reason      => 'glyph search subsidy after the fact',
    });
    $empire->update;

    return $self->view($session, $building);
}

sub view_excavators {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my @sites;
    my $level = $building->effective_level;
    my $chances = $building->can_you_dig_it($building->body, $level, 1);
    push @sites, {
        body     => $building->body->get_status,
        id       => 0,  # This makes it easy to tell which ID belongs to the building.
        artifact => $chances->{artifact},
        glyph    => $chances->{glyph},
        plan     => $chances->{plan},
        resource => $chances->{resource},
        date_landed => format_date($building->date_created),
        distance => 0,
    };
    my $excavators = $building->excavators;
    my $travel = Lacuna->db->resultset('Lacuna::DB::Result::Ships')
                ->search({type=>'excavator', task=>'Travelling',body_id=>$building->body_id})->count;
    while (my $excav = $excavators->next) {
      my $body = $excav->body;
      my $chances = $building->can_you_dig_it($body, $level, 0);
      push @sites, {
        body     => $excav->body->get_status,
        id       => $excav->id,
        artifact => $chances->{artifact},
        glyph    => $chances->{glyph},
        plan     => $chances->{plan},
        resource => $chances->{resource},
        date_landed => format_date($excav->date_landed),
        distance => sprintf("%.2f", $building->body->calculate_distance_to_target($excav->body) / 100),
      };
    }
    @sites = sort { 
        # closer first so player can see which ones are closer easily
        $a->{distance} <=> $b->{distance} or
        # if the distance is exactly the same (?), order of deployment
        # is close enough so that it remains (mostly) consistent.
        $a->{id} <=> $b->{id}
    } @sites;
    return {
        excavators       => \@sites,
        max_excavators   => $building->max_excavators,
        travelling       => $travel,
        status           => $self->format_status($empire, $building->body),
    };
}

sub abandon_excavator {
    my ($self, $session_id, $building_id, $site_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $site = Lacuna->db->resultset('Lacuna::DB::Result::Excavators')->find($site_id);
    unless (defined $site) {
        confess [1002, "Excavator Site :".$site_id.": not found."];
    }
    unless ($site->planet_id eq $building->body_id) {
        confess [1013, "You can't abandon an excavator site that is not from this planet."];
    }
    $building->remove_excavator($site);
    return {
        status  => $self->format_status($empire, $building->body),
    };
}

sub mass_abandon_excavator {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $building->excavators->delete;
	return {
        status  => $self->format_status($empire, $building->body),
    }; 
}

__PACKAGE__->register_rpc_method_names(qw(get_ores_available_for_processing assemble_glyphs search_for_glyph get_glyphs get_glyph_summary subsidize_search view_excavators abandon_excavator mass_abandon_excavator));


no Moose;
__PACKAGE__->meta->make_immutable;

