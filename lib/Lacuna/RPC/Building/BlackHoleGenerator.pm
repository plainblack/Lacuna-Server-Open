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

sub run_bhg {
  my ($self, $session_id, $building_id, $target_id, $task_name, $params) = @_;
  my $empire   = $self->get_empire_by_session($session_id);
  my $building = $self->get_building($empire, $building_id);
  my $body = $building->body;
  my $target   = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_id);
  unless (defined $target) {
    confess [1002, 'Could not locate target.'];
  }
  my @tasks = bhg_tasks();
  my ($task) = grep { $task_name eq $_->{name} } @tasks;
  unless ($task) {
    confess [1002, 'Could not find task: '.$task_name];
  }
  my $btype = $target->get_type;
  unless ( grep { $btype eq $_ } @{$task->{types}} ) {
    confess [1009, $task->{wrongtype}];
  }
  unless ($building->body->calculate_distance_to_target($target) < $building->level * 1000) {
    my $dist = sprintf "%7.2f", $building->body->calculate_distance_to_target($target);
    my $range = $building->level * 1000;
    confess [1009, 'That body is too far away at '.$dist.' with a range of '.$range.'. '.$target_id."\n"];
  }
  unless ($body->waste_stored >= $task->{waste}) {
    confess [1009, 'Attempt to start Black Hole Generator without enough waste mass is not allowed.'];
  }
  unless ($task->{occupied}) {
    if ($btype eq 'asteroid') {
      my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->
                      search({asteroid_id => $target_id });
      my $count = 0;
      while (my $platform = $platforms->next) {
        $count++;
      }
      if ($count) {
        $body->add_news(100, sprintf('Scientists revolt against %s for despicable practices.', $empire->name));
# Self Destruct BHG
        confess [1009, 'Your scientists refuse to destroy an asteroid with '.$count.' platforms.'];
      }
    }
    elsif (defined($body->empire) {
      $body->add_news(100,
             sprintf('Scientists revolt against %s for trying to turn %s into an asteroid.',
                     $empire->name, $target->name));
# Self Destruct BHG
      confess [1009, 'Your scientists refuse to destroy an inhabited body.'];
    }
  }
# Pass the basic checks
# Check for startup failure
  my $return_stats;
  if (($task->{fail_chance} - $building->level * 3) > randint(1,100) ) {
# Something went wrong with the start
    my $fail = randint(1,20);
    if ($fail < 2) {
      self_destruct_bhg($building);
      $body->add_news(100,
             sprintf('%s finds a decimal point out of place.',
                     $empire->name));
    }
    elsif ($fail <  7) {
      bhg_decor($body);
      $body->add_news(100,
             sprintf('%s is wracked with changes.',
                     $body->name));
    }
    elsif ($fail < 12) {
      bhg_resource($body, -1);
      $body->add_news(100,
             sprintf('%s opens up a wormhole near their storage area.',
                     $body->name));
    }
    elsif ($fail < 17) {
      bhg_size($building, $body, -1);
      $body->add_news(100,
             sprintf('%s deforms after an expirement goes wild.',
                     $body->name));
    }
    elsif ($fail < 20) {
      bhg_random_make($body);
      $body->add_news(100,
             sprintf('Scientists on %s are concerned when their singularity has a malfunction.',
                     $body->name));
    }
    else {
      bhg_random_type($body);
      $body->add_news(100,
             sprintf('Scientists on %s are concerned when their singularity has a malfunction.',
                     $body->name));
    }
  }
  else {
    if ($task->{name} eq "Make Planet") {
      bhg_make_planet($building, $target);
      $body->add_news(100,
                      sprintf('%s has expanded %s into a habitable world!',
                        $empire->name, $target->name));
    }
    elsif ($task->{name} eq "Make Asteroid") {
      bhg_make_asteroid($building, $target);
      $body->add_news(100, sprintf('%s has destroyed %s.', $empire->name, $target->name));
    }
    elsif ($task->{name} eq "Increase Size") {
      bhg_size($building, $target, 1);
      $body->add_news(100, sprintf('%s has expanded %s.', $empire->name, $target->name));
    }
    elsif ($task->{name} eq "Change Type") {
      bhg_change_type($building, $target, $params);
      $body->add_news(100, sprintf('%s has gone thru extensive changes.', $target->name));
    }
    else {
      confess [1009, "Internal Error"];
    }
  }
  return {
    status => $self->format_status($empire, $body, $target),
  };
}

sub bhg_make_planet {
  my ($building, $body) = @_;
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
 
  $body->update({
    class                       => $class,
    size                        => $size,
    usable_as_starter_enabled   => 0,
  });
  $body->sanitize;
}

sub bhg_make_asteroid {
  my ($building, $body) = @_;
  $planet->update({
    class                       => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,21),
    size                        => int($building->level/3),
    usable_as_starter_enabled   => 0,
  });
  $body->add_news(100, sprintf('%s has destroyed %s.', $empire->name, $planet->name));
}

sub bhg_random_make {
  my ($body) = @_;
# Find random non-occupied body
# Call make asteroid or make planet
}

sub bhg_self_destruct {
  my ($building) = @_;
# Blow up BHG, Splash damage
}

sub bhg_decor {
  my ($body) = @_;
# Find out how many open spaces are on planet.
# Fill in with decor
}

sub bhg_resource {
  my ($body, $bruce) = @_;
# If -1 deduct resources, if 0 randomize, if 1 add
}

sub bhg_change_type {
  my ($body, $params) = @_;
}

sub bhg_size {
  my ($building, $body, $bruce) = @_;
# If -1, subtract up to level (or min 30 size)
# If 0, add or subtract 5 (sizes can't go over 65 or under 30)
# if 1, add level
}

sub bhg_tasks {
  my $day_sec = 60 * 60 * 24;
  my @tasks = (
    {
      name         => 'Make Planet',
      types        => ['asteroid'],
      wrongtype    => "You can only make a planet from an asteroid.",
      occupied     => 0,
      min_level    => 10,
      recovery     => int($day_sec * 90/$building->level);
      waste        => 1_000_000_000,
      fail_chance  => 100,
      side_chance  => "high",
    },
    {
      name         => 'Make Asteroid',
      types        => ['habitable planet', 'gas giant'],
      wrongtype    => "You can only make an asteroid from a planet.",
      occupied     => 0,
      min_level    => 10,
      recovery     => int($day_sec * 90/$building->level);
      waste        => 10_000_000,
      fail_chance  => 100,
      side_chance  => "high",
    },
    {
      name         => 'Increase Size',
      types        => ['habitable planet', 'asteroid'],
      wrongtype    => "You can only increase the sizes of habitable planets and asteroids.",
      occupied     => 1,
      min_level    => 20,
      recovery     => int($day_sec * 90/$building->level);
      waste        => 10_000_000_000,
      fail_chance  => 100,
      side_chance  => "high",
    },
    {
      name         => 'Change Type',
      types        => ['habitable planet'],
      wrongtype    => "You can only change the type of habitable planets.",
      occupied     => 1,
      min_level    => 30,
      recovery     => int($day_sec * 90/$building->level);
      waste        => 100_000_000,
      fail_chance  => 100,
      side_chance  => "high",
    },
  );
  return @tasks;
}

# sub make_asteroid {
#     my ($self, $session_id, $building_id, $planet_id) = @_;
#     my $empire = $self->get_empire_by_session($session_id);
#     my $building = $self->get_building($empire, $building_id);
#     my $body = $building->body;
#     my $planet = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($planet_id);
#     
#     unless (defined $planet) {
#         confess [1002, 'Could not locate that planet.'];
#     }
#     unless ($planet->isa('Lacuna::DB::Result::Map::Body::Planet')) {
#         confess [1009, 'Black Hole Generator can only turn planets into asteroids.'];
#     }
#     unless ($building->body->calculate_distance_to_target($planet) < $building->level * 1000) {
#       my $dist = sprintf "%7.2f", $building->body->calculate_distance_to_target($planet);
#       my $range = $building->level * 1000;
#       confess [1009, 'That asteroid is too far away at '.$dist.' with a range of '.$range.'. '.$planet_id."\n"];
#     }
#     if (defined($planet->empire)) {
#       $body->add_news(100, sprintf('Scientists revolt against %s for trying to turn %s into an asteroid.', $empire->name, $planet->name));
# # Self Destruct BHG
#       confess [1009, 'Your scientists refuse to destroy an inhabited planet.'];
#     }
#     $planet->update({
#        class                       => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,21),
#        size                        => int($building->level/3),
#        usable_as_starter_enabled   => 0,
#     });
#     $body->add_news(100, sprintf('%s has destroyed %s.', $empire->name, $planet->name));
# 
#     return {
#       status => $self->format_status($empire, $planet),
#     }
# }
# 
# sub make_planet {
#     my ($self, $session_id, $building_id, $asteroid_id) = @_;
#     my $empire = $self->get_empire_by_session($session_id);
#     my $building = $self->get_building($empire, $building_id);
#     my $body = $building->body;
#     my $asteroid = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($asteroid_id);
#     
#     unless (defined $asteroid) {
#         confess [1002, 'Could not locate that asteroid.'];
#     }
# 
#     unless ($building->body->calculate_distance_to_target($asteroid) < $building->level * 1000) {
#       my $dist = sprintf "%7.2f", $building->body->calculate_distance_to_target($asteroid);
#       my $range = $building->level * 1000;
#       confess [1009, 'That asteroid is too far away.'];
#     }
# 
#     unless ($asteroid->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
#         confess [1009, 'Black Hole Generator can only turn asteroids into planets.'];
#     }
# 
#     my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->
#                       search({asteroid_id => $asteroid_id });
#     my $count = 0;
#     while (my $platform = $platforms->next) {
#       $count++;
#     }
# 
#     if ($count) {
#       $body->add_news(100, sprintf('Scientists revolt against %s despicable practices.', $empire->name));
#       confess [1009, 'Your scientists refuse to destroy an asteroid with '.$count.' platforms.'];
#     }
#     my $class;
#     my $size;
#     my $random = randint(1,100);
#     if ($random < 6) {
#       $class = 'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G'.randint(1,5);
#       $size  = randint(70, 121);
#     }
#     else {
#       $class = 'Lacuna::DB::Result::Map::Body::Planet::P'.randint(1,20);
#       $size  = 25+int($building->level/2);
#     }
# 
#     $asteroid->update({
#        class                       => $class,
#        size                        => $size,
#        usable_as_starter_enabled   => 0,
#     });
#     $body->add_news(100, sprintf('%s has expanded %s into a habitable world!', $empire->name, $asteroid->name));
# 
#     return {
#       status => $self->format_status($empire, $asteroid),
#     }
# }

__PACKAGE__->register_rpc_method_names(qw(run_bhg));

no Moose;
__PACKAGE__->meta->make_immutable;

