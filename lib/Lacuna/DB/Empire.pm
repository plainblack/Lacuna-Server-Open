package Lacuna::DB::Empire;

use Moose;
extends 'SimpleDB::Class::Item';
use DateTime;
use Lacuna::Util;

__PACKAGE__->set_domain_name('empire');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str', 
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->cname(Lacuna::Util::cname($new));
        },
    },
    cname           => { isa => 'Str' },
    date_created    => { isa => 'DateTime' },
    description     => { isa => 'Str' },
    status_message  => { isa => 'Str' },
    friends_and_foes=> { isa => 'Str' },
    password        => { isa => 'Str' },
    last_login      => { isa => 'DateTime' },
    species_id      => { isa => 'Str' },
    happiness       => { isa => 'Int' },
    essentia        => { isa => 'Int' },
    points          => { isa => 'Int' },
    rank            => { isa => 'Int' }, # just where it is stored, but will come out of date quickly
);

# achievements
# personal confederacies

__PACKAGE__->belongs_to('species', 'Lacuna::DB::Species', 'species_id');
__PACKAGE__->has_many('sessions', 'Lacuna::DB::Session', 'empire_id');
__PACKAGE__->has_many('alliance', 'Lacuna::DB::AllianceMember', 'alliance_id');
__PACKAGE__->has_many('planets', 'Lacuna::DB::Planet', 'empire_id');

sub start_session {
    my $self = shift;
    my $session = $self->simpledb->domain('session')->insert({
        empire_id       => $self->id,
        date_created    => DateTime->now,
        expires         => DateTime->now->add(hours=>2),
    });
    $self->last_login(DateTime->now);
    $self->put;
    return $session;
}

no Moose;
__PACKAGE__->meta->make_immutable;
