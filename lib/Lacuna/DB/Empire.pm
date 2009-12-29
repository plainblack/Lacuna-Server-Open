package Lacuna::DB::Empire;

use Moose;
extends 'SimpleDB::Class::Item';
use Digest::SHA;
use DateTime;

__PACKAGE__->set_domain_name('empire');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str' },
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

sub authenticate_password {
    my ($self, $password) = @_;
    return ($self->password eq $self->encrypt_password($password));
}

sub encrypt_password {
    my ($self, $password) = @_;
    return Digest::SHA::sha256_base64($password);
}

sub start_session {
    my $self = shift;
    my $session = $self->simpledb->domain('session')->insert({
        empire_id       => $self->id,
        date_created    => DateTime->now,
        expires         => DateTime->now->add(hours=>2),
    });
    return $session;
}

no Moose;
__PACKAGE__->meta->make_immutable;
