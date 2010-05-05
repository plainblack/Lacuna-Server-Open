package Lacuna::DB::Result::Spies;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('spies');
__PACKAGE__->add_columns(
    empire_id               => { data_type => 'int', size => 11, is_nullable => 0 },
    name                    => { data_type => 'char', size => 30, is_nullable => 0, default_value => 'Agent Null' },
    from_body_id            => { data_type => 'int', size => 11, is_nullable => 0 },
    on_body_id              => { data_type => 'int', size => 11, is_nullable => 0 },
    task                    => { data_type => 'char', size => 30, is_nullable => 0, default_value => 'Idle' },
    available_on            => { data_type => 'datetime', is_nullable => 0, default_value => DateTime->now },
    offense                 => { data_type => 'int', size => 11, default_value => 1 },
    defense                 => { data_type => 'int', size => 11, default_value => 1 },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');
__PACKAGE__->belongs_to('from_body', 'Lacuna::DB::Result::Body::Planet', 'from_body_id');
__PACKAGE__->belongs_to('on_body', 'Lacuna::DB::Result::Body::Planet', 'on_body_id');

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
    'Counter Espionage',
    'Gather Intelligence',
    'Hack Networks',
    'Appropriate Technology',
    'Sabotage Infrastructure',
    'Incite Rebellion',
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

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
