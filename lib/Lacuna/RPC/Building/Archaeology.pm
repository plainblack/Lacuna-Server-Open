package Lacuna::RPC::Building::Archaeology;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/archaeology';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Archaeology';
}

sub get_glyphs {
    my ($self, $session_id, $building_id, $onoff) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @out;
    my $glyphs = $building->glyphs;
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

sub search_for_glyph {
    my ($self, $session_id, $building_id, $ore) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->search_for_glyph($ore);
    return {
        seconds_remaining   => $building->work_seconds_remaining,
        status              => $self->format_status($empire, $building->body),
    };
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


__PACKAGE__->register_rpc_method_names(qw(assemble_glyphs search_for_glyph get_glyphs));


no Moose;
__PACKAGE__->meta->make_immutable;

