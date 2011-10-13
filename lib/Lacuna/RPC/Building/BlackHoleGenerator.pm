package Lacuna::RPC::Building::BlackHoleGenerator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Util qw(randint);

sub app_url {
    return '/blackholegenerator';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator';
}

sub make_asteroid {
    my ($self, $session_id, $building_id, $planet_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    my $planet = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($planet_id);
    
    unless (defined $planet) {
        confess [1002, 'Could not locate that planet.'];
    }
    unless ($planet->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [1009, 'Black Hole Generator can only turn planets into asteroids.'];
    }
    unless ($building->body->calculate_distance_to_target($planet) < $building->level * 1000) {
      my $dist = sprintf "%7.2f", $building->body->calculate_distance_to_target($planet);
      my $range = $building->level * 1000;
      confess [1009, 'That planet is too far away at '.$dist.' with a range of '.$range.'. '.$planet_id."\n"];
    }
    if (defined($planet->empire)) {
      $body->add_news(100, sprintf('Scientists revolt against %s for trying to turn %s into an asteroid.', $empire->name, $planet->name));
# Self Destruct BHG
      confess [1009, 'Your scientists refuse to destroy an inhabited planet.'];
    }
    $planet->update({
       class                       => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,21),
       size                        => int($building->level/3),
       usable_as_starter_enabled   => 0,
    });
    $body->add_news(100, sprintf('%s has destroyed %s.', $empire->name, $planet->name));

    return {
      status => $self->format_status($empire, $planet),
    }
}

sub make_planet {
    my ($self, $session_id, $building_id, $asteroid_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    my $asteroid = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($asteroid_id);
    
    unless (defined $asteroid) {
        confess [1002, 'Could not locate that asteroid.'];
    }

    unless ($building->body->calculate_distance_to_target($asteroid) < $building->level * 1000) {
      my $dist = sprintf "%7.2f", $building->body->calculate_distance_to_target($asteroid);
      my $range = $building->level * 1000;
      confess [1009, 'That asteroid is too far away.'];
    }

    unless ($asteroid->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        confess [1009, 'Black Hole Generator can only turn asteroids into planets.'];
    }

    my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->
                      search({asteroid_id => $asteroid_id });
    my $count = 0;
    while (my $platform = $platforms->next) {
      $count++;
    }

    if ($count) {
      $body->add_news(100, sprintf('Scientists revolt against %s despicable practices.', $empire->name));
      confess [1009, 'Your scientists refuse to destroy an asteroid with '.$count.' platforms.'];
    }
    my $class;
    my $size;
    my $random = randint(1,100);
    if ($random < 6) {
      $class = 'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G'.randint(1,5);
      $size  = randint(70, 121);
    }
    else {
      $class = 'Lacuna::DB::Result::Map::Body::Planet::P'.randint(1,20);
      $size  = 25+int($building->level/2);
    }

    $asteroid->update({
       class                       => $class,
       size                        => $size,
       usable_as_starter_enabled   => 0,
    });
    $body->add_news(100, sprintf('%s has expanded %s into a habitable world!', $empire->name, $asteroid->name));

    return {
      status => $self->format_status($empire, $asteroid),
    }
}

__PACKAGE__->register_rpc_method_names(qw(make_asteroid make_planet));

no Moose;
__PACKAGE__->meta->make_immutable;

