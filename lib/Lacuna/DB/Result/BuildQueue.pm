package Lacuna::DB::Result::BuildQueue;

use Moose;
extends 'Lacuna::DB::Result';
use DateTime;
use Lacuna::Util qw(to_seconds format_date);

__PACKAGE__->table('build_queue');
__PACKAGE__->add_columns(
    date_created        => { data_type => 'datetime', is_nullable => 0 },
    date_complete       => { data_type => 'datetime', is_nullable => 0 },
    empire_id           => { data_type => 'int', size => 11, is_nullable => 0 },
    building_class      => { data_type => 'char', size => 255, is_nullable => 0 },
    building_id         => { data_type => 'int', size => 11, is_nullable => 0 },
    body_id             => { data_type => 'int', size => 11, is_nullable => 0 },
);

#__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');
#__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Body', 'body_id');

sub date_complete_formatted {
    my $self = shift;
    return format_date($self->date_complete);
}

has building => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $building = $self->empire->get_building($self->building_class, $self->building_id);
        $building->build_queue($self); # avoid stale build queue
        if ($self->has_body) { # avoid stale body on tick
            $building->body($self->body);
        }
        return $building;
    },
);

sub seconds_remaining {
    my $self = shift;
    return to_seconds($self->date_complete - DateTime->now);
}

sub get_status {
    my ($self, $building) = @_;
    my $now = DateTime->now;
    my $complete = $self->date_complete;
    if ($now > $complete) {
        return undef;
    }
    else {
        return {
            seconds_remaining   => to_seconds($complete - $now),
            start               => format_date($self->date_created),
            end                 => format_date($self->date_complete),
        };
    }
}

sub finish_build {
    my $self = shift;
    $self->building->finish_upgrade;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
