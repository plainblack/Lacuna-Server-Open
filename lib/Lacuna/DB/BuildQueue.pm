package Lacuna::DB::BuildQueue;

use Moose;
extends 'SimpleDB::Class::Item';
use DateTime;
use Lacuna::Util qw(to_seconds format_date);

__PACKAGE__->set_domain_name('build_queue');
__PACKAGE__->add_attributes(
    date_created        => { isa => 'DateTime' },
    date_complete       => { isa => 'DateTime' },
    empire_id           => { isa => 'Str' },
    building_class      => { isa => 'Str' },
    building_id         => { isa => 'Str' },
    body_id             => { isa => 'Str' },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body', 'body_id');

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
    return to_seconds(DateTime->now - $self->date_complete);
}

sub check_status {
    my ($self, $building) = @_;
    my $now = DateTime->now;
    my $complete = $self->date_complete;
    if ($now > $complete) {
        $building ||= $self->building;
        $building->finish_upgrade;
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

no Moose;
__PACKAGE__->meta->make_immutable;
