package Lacuna::RPC::Building::Archaeology;

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
    my $orig = shift;
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id}, skip_offline => 1);

    my $out = $orig->($self, $empire, $building);
    if ($building->is_working) {
        $out->{building}{work}{searching} = $building->work->{ore_type};
    }
    return $out;
};


sub get_glyphs {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});


    my @out;
    my $glyphs = $building->body->glyph;
    while (my $glyph = $glyphs->next) {
        push @out, {
            id          => $glyph->id,
            name        => $glyph->type,
            type        => $glyph->type,
            quantity    => $glyph->quantity,
        };
    }
    return {
        glyphs  => \@out,
        status  => $self->format_status($empire, $building->body),
    };
}


sub get_glyph_summary {
    my ($self, $args) = @_;
    return $self->get_glyphs(@_);
}


sub get_ores_available_for_processing {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});

    return {
        ore                 => $building->get_ores_available_for_processing,
        status              => $self->format_status($empire, $building->body),
    };
}


sub search_for_glyph {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            ore             => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});

    $building->search_for_glyph($args->{ore});
    return $self->view($empire, $building);
}


sub assemble_glyphs {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            glyphs          => shift,
            quantity        => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $quantity    = defined $args->{quantity} ? $args->{quantity} : 1;

    if ($quantity > 50) {
        confess [1011, "You can only assemble up to 50 plans at a time"];
    }
    if ($quantity <= 0 or int($quantity) != $quantity) {
        confess [1001, "Quantity must be a positive integer"];
    }

    my $plan = $building->make_plan($args->{glyphs}, $quantity);
    return {
        item_name           => $plan->class->name,
        status              => $self->format_status($empire, $building->body),
    };
}



sub subsidize_search {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});

    unless ($building->is_working) {
        confess [1010, "No one is searching."];
    }
 
    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];    
    }

    $building->finish_work->update;
    $empire->spend_essentia(2, 'glyph search subsidy after the fact');    
    $empire->update;

    return $self->view($empire, $building);
}

sub view_excavators {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});

    my @sites;
    my $level = $building->level;
    my $chances = $building->can_you_dig_it($building->body, $level, 1);
    push @sites, {
        body     => $building->body->get_status,
        id       => 0,  # This makes it easy to tell which ID belongs to the building.
        artifact => $chances->{artifact},
        glyph    => $chances->{glyph},
        plan     => $chances->{plan},
        resource => $chances->{resource},
    };
    my $excavators = $building->excavators;
    my $travel = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
        type    => 'excavator', 
        task    => 'Travelling',
        body_id => $building->body_id,
    })->count;

    while (my $excav = $excavators->next) {
        my $body = $excav->body;
        my $chances = $building->can_you_dig_it($body, $level, 0);
        push @sites, {
            body        => $excav->body->get_status,
            id          => $excav->id,
            artifact    => $chances->{artifact},
            glyph       => $chances->{glyph},
            plan        => $chances->{plan},
            resource    => $chances->{resource},
        };
    }
    return {
        excavators      => \@sites,
        max_excavators  => $building->max_excavators,
        travelling      => $travel,
        status          => $self->format_status($empire, $building->body),
    };
}


sub abandon_excavator {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            site_id         => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $site_id     = $args->{site_id};
    my $site        = Lacuna->db->resultset('Lacuna::DB::Result::Excavators')->find($site_id);

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

__PACKAGE__->register_rpc_method_names(qw(
    get_ores_available_for_processing 
    assemble_glyphs 
    search_for_glyph 
    get_glyphs 
    get_glyph_summary 
    subsidize_search 
    view_excavators 
    abandon_excavator
));

no Moose;
__PACKAGE__->meta->make_immutable;

