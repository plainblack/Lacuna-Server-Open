package Lacuna::DB::BuildQueue;

use Moose;
extends 'SimpleDB::Class::Item';
use DateTime;
use Lacuna::Util qw(to_seconds);

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

sub building {
    my ($self) = @_;
    return $self->simpledb->domain($self->building_class)->find($self->building_id);
}

sub seconds_remaining {
    my $self = shift;
    return to_seconds(DateTime->now - $self->date_complete);
}

sub is_complete {
    my ($self, $building) = @_;
    my $now = DateTime->now;
    my $complete = $self->date_complete;
    if ($now > $complete) {
        $building ||= $self->building;
        $building->finish_upgrade;
        $self->delete;
        return 0;
    }
    else {
        return to_seconds($complete - $now);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
