package Lacuna::RPC::Building::Archaeology;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/archaeology';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Archaeology';
}

sub get_glyphs {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @out;
    my $glyphs = $building->body->glyphs;
    while (my $glyph = $glyphs->next) {
        push @out, {
            id      => $glyph->id,
            type    => $glyph->type,
        };
    }
    return {
        glyphs  => \@out,
        status  => $self->format_status($empire, $building->body),
    };
}

sub get_ores_available_for_processing {
    my ($self, $session_id, $building_id, $ore) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    return {
        ore                 => $building->get_ores_available_for_processing,
        status              => $self->format_status($empire, $building->body),
    };
}

sub search_for_glyph {
    my ($self, $session_id, $building_id, $ore) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->search_for_glyph($ore);
    return $self->view($empire, $building);
}

sub assemble_glyphs {
    my ($self, $session_id, $building_id, $ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $plan = $building->make_plan($ids);
    return {
        item_name           => $plan->class->name,
        status              => $self->format_status($empire, $building->body),
    };
}



sub subsidize_search {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

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


__PACKAGE__->register_rpc_method_names(qw(get_ores_available_for_processing assemble_glyphs search_for_glyph get_glyphs subsidize_search));


no Moose;
__PACKAGE__->meta->make_immutable;

