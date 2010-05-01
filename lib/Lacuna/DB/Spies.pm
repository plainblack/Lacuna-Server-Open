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

sub kill {
    my ($self, $body) = @_;
    $body ||= $self->on_body;
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_killed.txt',
        params      => [$self->name, $body->name],
    );
    $self->delete;
}

sub escape {
    my ($self, $body) = @_;
    $self->available_on(DateTime->now);
    $self->task('Idle');
    $self->put;
    my $evil_empire = $self->on_body->empire;
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'i_have_escaped.txt',
        params      => [$evil_empire->name, $self->name],
    );
    $evil_empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'you_cant_hold_me.txt',
        params      => [$self->name],
    );
}

sub turn {
    my ($self, $rebel) = @_;
    my $evil_empire = $self->on_body->empire;
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'goodbye.txt',
        params      => [$self->name],
    );
    $rebel->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'new_recruit.txt',
        params      => [$self->empire->name, $self->name, $rebel->name],
    );
    # could be abused to get lots of extra spies, may have to add a check for that.
    $self->task('Idle');
    $self->empire_id($rebel->empire_id);
    $self->from_body_id($rebel->from_body_id);
    $self->put;
}

sub sabotage_a_building {
    my ($self, $building) = @_;
    my $body = $building->body;
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'sabotage_report.txt',
        params      => [$building->name, $body->name, $self->name],
    );
    $body->interception_score( $body->interception_score + 20);
}

sub sabotage_a_ship {
    my ($self, $building, $type) = @_;
    my $body = $building->body;
    $type =~ s/_/ /g;
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'sabotage_report.txt',
        params      => [$type, $body->name, $self->name],
    );
    $body->interception_score( $body->interception_score + 10);
}





no Moose;
__PACKAGE__->meta->make_immutable;
