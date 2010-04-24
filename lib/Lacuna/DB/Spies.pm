package Lacuna::DB::Spies;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->set_domain_name('spies');
__PACKAGE__->add_attributes(
    empire_id               => { isa => 'Str' },
    name                    => { isa => 'Str', default => 'Agent Null' },
    from_body_id            => { isa => 'Str' },
    on_body_id              => { isa => 'Str' },
    task                    => { isa => 'Str' },
    available_on            => { isa => 'DateTime' },
    offense                 => { isa => 'Int', default => 1 },
    defense                 => { isa => 'Int', default => 1 },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->belongs_to('from_body', 'Lacuna::DB::Body::Planet', 'from_body_id');
__PACKAGE__->belongs_to('on_body', 'Lacuna::DB::Body::Planet', 'on_body_id');

sub format_available_on {
    my ($self) = @_;
    return format_date($self->available_on);
}

sub is_available {
    my ($self) = @_;
    if (DateTime->now > $self->available_on) {
        if ($self->task eq 'Travelling' || $self->task eq 'Training' || $self->task eq 'Captured') {
            $self->task('Idle');
            $self->put;
        }
        return 1;
    }
    return 0;
}

use constant assignments => (
    'Idle',
    'Gather Intelligence',
    'Capture Spies',
    'Sabotage Infrastructure',
    'Appropriate Technology',
    'Incite Rebellion',
    'Hack Networks'
);

sub assign {
    my ($self, $assignment) = @_;
    my @assignments = $self->assignments;
    unless ($assignment ~~ @assignments) {
        confess [1009, "You can't assign a spy a task that he's not trained for."];
    }
    unless ($self->is_available) {
        confess [1013, "This spy is unavailable for reassignment."];
    }
    $self->task($assignment);
    return $self;
}

sub steal_a_building {
    my ($self, $building) = @_;
    if ($building->level == 0) {
        $self->from_body->add_free_build($building->class, 1);
    }
    else {
        $self->from_body->add_free_upgrade($building->class, $building->level + 1);
    }
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'stole_a_building.txt',
        params      => [$building->level + 1, $building->name, $self->name],
    );
}

sub sabotage_a_building {
    my ($self, $building) = @_;
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'sabotage_report.txt',
        params      => [$building->name, $building->body->name, $self->name],
    );
}

sub sabotage_a_ship {
    my ($self, $building, $type) = @_;
    $type =~ s/_/ /g;
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'sabotage_report.txt',
        params      => [$type, $building->body->name, $self->name],
    );
}





no Moose;
__PACKAGE__->meta->make_immutable;
