package Lacuna::DB::Result::SabenTarget;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('saben_target');
__PACKAGE__->add_columns(
    target_empire_id        => { data_type => 'int', is_nullable => 0 },
    saben_colony_id        => { data_type => 'int', is_nullable => 0 },
);

sub saben_colony {
    my $self = shift;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($self->saben_colony_id);
    if (defined $body && $body->empire_id == -1) {
        return $body;
    }
    else {
        $self->delete;
        return undef;
    }
}

sub target_empire {
    my $self = shift;
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($self->target_empire_id);
    return (defined $empire) ? $empire : $self->find_new_target;
}

sub find_new_target {
    my $self = shift;
    my $saben_colony = $self->saben_colony;
    return undef unless (defined $saben_colony);
    my $db = Lacuna->db;
    my @empire_ids = $db->resultset('Lacuna::DB::Result::Log::Empire')->search(undef,{
        order_by    => 'empire_size_rank',
        rows        => 50,
    })->all;
    my $potential = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
        zone        => $saben_colony->zone,
        empire_id   => { 'in' => \@empire_ids },
    });
    my $target = $potential->next;
    unless (defined $target) {
        $self->delete;
        return undef;
    }
    while (my $try = $potential->next) {
        if ($saben_colony->calculate_distance_to_target($try) < $saben_colony->calculate_distance_to_target($target)) {
            $target = $try;
        }
    }
    $self->target_empire_id($target->empire_id);
    $self->update;
    return $target->empire;
}

sub find_closest_target_planet {
    my $self = shift;
    my $saben_colony = $self->saben_colony;
    return undef unless (defined $saben_colony);
    my $potential = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({
        empire_id   => $self->target_empire->id,
    });
    my $target = $potential->next;
    unless (defined $target) {
        $self->delete;
        return undef;
    }
    while (my $try = $potential->next) {
        if ($saben_colony->calculate_distance_to_target($try) < $saben_colony->calculate_distance_to_target($target)) {
            $target = $try;
        }
    }
    return $target;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
