package Lacuna::DB::Spies;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->set_domain_name('spies');
__PACKAGE__->add_attributes(
    from_body_id            => { isa => 'Str' },
    on_body_id              => { isa => 'Str' },
    task                    => { isa => 'Str' },
    available_on            => { isa => 'DateTime' },
);

__PACKAGE__->belongs_to('from_body', 'Lacuna::DB::Body::Planet', 'from_body_id');
__PACKAGE__->belongs_to('on_body', 'Lacuna::DB::Body::Planet', 'on_body_id');

sub format_available_on {
    my ($self) = @_;
    return format_date($self->available_on);
}

sub is_available {
    my ($self) = @_;
    if (DateTime->now > $self->available_on) {
        if ($self->task eq 'Travelling' || $self->task eq 'Training') {
            $self->task('Idle');
            $self->put;
        }
        return 1;
    }
    return 0;
}

use constant assignments => (
    'Idle',
    'Counter Intelligence',
    'Sting',
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
__PACKAGE__->meta->make_immutable;
