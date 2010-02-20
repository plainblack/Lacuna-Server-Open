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

sub current_planet {
    my ($self) = @_;
    $self->simpledb->domain('body')->find($self->current_planet_id);
}

sub get_status {
    my ($self) = @_;
    my $planet_rs = $self->planets;
    my %planets;
    while (my $planet = $planet_rs->next) {
        $planets{$planet->id} = {
            name            => $planet->name,
            image           => $planet->image,
            x               => $planet->x,
            y               => $planet->y,
            z               => $planet->z,
            orbit           => $planet->orbit,
        };
        if ($self->current_planet_id eq $planet->id) { # is current planet
            $planet->tick;
            
            ## add capacity
            
            my $current = $planets{$planet->id};
            $current->{water_stored}    = $planet->water_stored;
            $current->{water_hour}      = $planet->water_hour;
            $current->{energy_stored}   = $planet->energy_stored;
            $current->{energy_hour}     = $planet->energy_hour;
            $current->{food_stored}     = $planet->food_stored;
            $current->{food_hour}       = $planet->food_stored;
            $current->{ore_stored}      = $planet->ore_stored;
            $current->{ore_hour}        = $planet->ore_hour;
            $current->{waste_stored}    = $planet->waste_stored;
            $current->{waste_hour}      = $planet->waste_hour;
            $current->{happiness}       = $planet->happiness;
            $current->{happiness_hour}  = $planet->happiness_hour;
            
        }
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
