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
    cname               => { isa => 'Str' },
    date_created        => { isa => 'DateTime' },
    description         => { isa => 'Str' },
    home_planet_id      => { isa => 'Str' },
    current_planet_id   => { isa => 'Str' },
    status_message      => { isa => 'Str' },
    friends_and_foes    => { isa => 'Str' },
    password            => { isa => 'Str' },
    last_login          => { isa => 'DateTime' },
    species_id          => { isa => 'Str' },
    happiness           => { isa => 'Int', default=>0 },
    essentia            => { isa => 'Int', default=>0 },
    points              => { isa => 'Int', default=>0 },
    rank                => { isa => 'Int', default=>0 }, # just where it is stored, but will come out of date quickly
    probed_stars        => { isa => 'Str' },
);

# achievements
# personal confederacies

__PACKAGE__->belongs_to('species', 'Lacuna::DB::Species', 'species_id');
__PACKAGE__->has_many('sessions', 'Lacuna::DB::Session', 'empire_id');
__PACKAGE__->has_many('alliance', 'Lacuna::DB::AllianceMember', 'alliance_id');
__PACKAGE__->has_many('planets', 'Lacuna::DB::Body::Planet', 'empire_id');

sub home_planet {
    my ($self) = @_;
    $self->simpledb->domain('body')->find($self->home_planet_id);
}

sub current_planet {
    my ($self) = @_;
    $self->simpledb->domain('body')->find($self->current_planet_id);
}

sub get_status {
    my ($self) = @_;
    my $planet_rs = $self->planets;
    my %planets;
    while (my $planet = $planet_rs->next) {
        $planet->recalc_stats;
        $planets{$planet->id} = {
            name        => $planet->name,
            image       => $planet->image,
            water       => $planet->water_stored,
       #     food        => $planet->food_stored,
        #    minerals    => $planet->minerals_stored,
            waste       => $planet->waste_stored,
            happiness   => $planet->happiness,
        };
    }
    $self = $self->simpledb->domain('empire')->find($self->id); # refetch because it's likely changed
    my $status = {
        server  => {
            "time" => DateTime::Format::Strptime::strftime('%d %m %Y %H:%M:%S %z',DateTime->now),
        },
        empire  => {
            happiness           => $self->happiness,
            name                => $self->name,
            id                  => $self->id,
            essentia            => $self->essentia,
            has_new_messages    => 0,
            current_planet_id   => $self->current_planet_id,
            planets             => \%planets,
        },
    };
    return $status;
}

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
