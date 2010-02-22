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
    status_message      => { isa => 'Str' },
    friends_and_foes    => { isa => 'Str' },
    password            => { isa => 'Str' },
    last_login          => { isa => 'DateTime' },
    species_id          => { isa => 'Str' },
    essentia            => { isa => 'Int', default=>0 },
    points              => { isa => 'Int', default=>0 },
    rank                => { isa => 'Int', default=>0 }, # just where it is stored, but will come out of date quickly
    probed_stars        => { isa => 'Str' },
    university_level    => { isa => 'Int', default=>0 },
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

sub get_status {
    my ($self) = @_;
    my $planet_rs = $self->planets;
    my %planets;
    my $happiness = 0;
    my $happiness_hour = 0;
    while (my $planet = $planet_rs->next) {
        $happiness += $planet->happiness;
        $happiness_hour += $planet->happiness_hour;
    }
    $self = $self->simpledb->domain('empire')->find($self->id); # refetch because it's likely changed
    my $status = {
        server  => {
            "time" => DateTime::Format::Strptime::strftime('%d %m %Y %H:%M:%S %z',DateTime->now),
        },
        empire  => {
            full_status_update_required => 0,
            happiness                   => $happiness,
            happiness_hour              => $happiness_hour,
            essentia                    => $self->essentia,
            has_new_messages            => 0,
        },
    };
    return $status;
}

sub get_full_status {
    my ($self) = @_;
    my $planet_rs = $self->planets;
    my %planets;
    my $happiness = 0;
    my $happiness_hour = 0;
    while (my $planet = $planet_rs->next) {
        $planet->tick;
        $planets{$planet->id} = {
            name            => $planet->name,
            image           => $planet->image,
            x               => $planet->x,
            y               => $planet->y,
            z               => $planet->z,
            orbit           => $planet->orbit,
            water_capacity  => $planet->water_capacity,
            water_stored    => $planet->water_stored,
            water_hour      => $planet->water_hour,
            energy_capacity => $planet->energy_capacity,
            energy_stored   => $planet->energy_stored,
            energy_hour     => $planet->energy_hour,
            food_capacity   => $planet->food_capacity,
            food_stored     => $planet->food_stored,
            food_hour       => $planet->food_stored,
            ore_capacity    => $planet->ore_capacity,
            ore_stored      => $planet->ore_stored,
            ore_hour        => $planet->ore_hour,
            waste_capacity  => $planet->waste_capacity,
            waste_stored    => $planet->waste_stored,
            waste_hour      => $planet->waste_hour,
            happiness       => $planet->happiness,
            happiness_hour  => $planet->happiness_hour,
        };
        $happiness += $planet->happiness;
        $happiness_hour += $planet->happiness_hour;
    }
    my $status = {
        server  => {
            "time" => DateTime::Format::Strptime::strftime('%d %m %Y %H:%M:%S %z',DateTime->now),
        },
        empire  => {
            happiness           => $happiness,
            happiness_hour      => $happiness_hour,
            name                => $self->name,
            id                  => $self->id,
            essentia            => $self->essentia,
            has_new_messages    => 0,
            home_planet_id      => $self->home_planet_id,
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
