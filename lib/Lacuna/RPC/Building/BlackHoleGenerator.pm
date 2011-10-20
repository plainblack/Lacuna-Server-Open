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
  my @tasks = bhg_tasks($building);
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
        bhg_self_destruct($building);
        confess [1009, 'Your scientists refuse to destroy an asteroid with '.$count.' platforms.'];
      }
    }
    elsif (defined($target->empire)) {
      $body->add_news(100,
             sprintf('Scientists revolt against %s for trying to turn %s into an asteroid.',
                     $empire->name, $target->name));
      bhg_self_destruct($building);
      confess [1009, 'Your scientists refuse to destroy an inhabited body.'];
    }
  }
# Pass the basic checks
# Check for startup failure
  my $return_stats;
  my $fail = randint(1,100);
  print "Fail: $fail\n";
  if (($task->{fail_chance} > $fail )) {
# Something went wrong with the start
    $fail = randint(1,20);
    if ($fail < 2) {
      bhg_self_destruct($building);
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
      bhg_change_type($target, $params);
      $body->add_news(100, sprintf('%s has gone thru extensive changes.', $target->name));
    }
    else {
      confess [1009, "Internal Error"];
    }
#And now side effect time
  }
  return {
    status => $self->format_status($empire, $body),
    target => $target->get_status($target),
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
  $body->update({
    class                       => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,21),
    size                        => int($building->level/5),
    usable_as_starter_enabled   => 0,
    alliance_id => undef,
  });
}

sub bhg_random_make {
  my ($body) = @_;
print "Random Make!\n";
# Find random non-occupied body
# Call make asteroid or make planet
}

sub bhg_self_destruct {
  my ($building) = @_;
print "Boom!\n";
# Blow up BHG, Splash damage
}

sub bhg_decor {
  my ($body) = @_;
print "Decor explosion!\n";
# Find out how many open spaces are on planet.
# Fill in with decor
}

sub bhg_resource {
  my ($body, $bruce) = @_;
print "Resource shuffle $bruce\n";
# If -1 deduct resources, if 0 randomize, if 1 add
  my @food = qw( algae_stored apple_stored bean_stored beetle_stored
                 bread_stored burger_stored cheese_stored chip_stored
                 cider_stored corn_stored fungus_stored lapis_stored
                 meal_stored milk_stored pancake_stored pie_stored
                 potato_stored root_stored shake_stored soup_stored
                 syrup_stored wheat_stored
  );
  my @ore = qw( anthracite_stored bauxite_stored beryl_stored chalcopyrite_stored
                chromite_stored fluorite_stored galena_stored goethite_stored
                gold_stored gypsum_stored halite_stored kerogen_stored
                magnetite_stored methane_stored monazite_stored rutile_stored
                sulfur_stored trona_stored uraninite_stored zircon_stored
  );
# Waste always reacts oddly
  my $waste_rnd = randint(1,5);
  if ($waste_rnd > 3) {
    $body->waste_stored($body->waste_capacity);
  }
  elsif ($waste_rnd < 3) {
    $body->waste_stored(0);
  }
  else {
    $body->waste_stored(randint(0, $body->waste_capacity));
  }
# Other resources
  if ($bruce == 1) {
    $body->water_stored(randint($body->water_stored, $body->water_capacity));
    $body->energy_stored(randint($body->energy_stored, $body->energy_capacity));
    my $arr = rand_perc(scalar @food);
    my $food_stored = 0;
    for my $attrib (@food) { $food_stored += $body->$attrib; }
    my $food_room = $body->food_capacity - $food_stored;
    for (0..(scalar @food - 1)) {
      $body->{$food[$_]}(randint($body->{$food[$_]},
                              int($food_room * $arr->[$_]/100) ));
    }
    $arr = rand_perc(scalar @ore);
    my $ore_stored = 0;
    for my $attrib (@ore) { $ore_stored += $body->$attrib; }
    my $ore_room = $body->ore_capacity - $ore_stored;
    for (0..(scalar @ore - 1)) {
      $body->{$ore[$_]}(randint($body->{$ore[$_]},
                              int($ore_room * $arr->[$_]/100) ));
    }
  }
  elsif ($bruce == -1) {
    $body->water_stored(randint(0, $body->water_stored));
    $body->energy_stored(randint(0, $body->energy_stored));
    foreach my $attribute (@food, @ore) {
      next unless $body->$attribute;
      $body->$attribute(randint(0, $body->$attribute));
    }
  }
  else {
    $body->water_stored(randint(0, $body->water_capacity));
    $body->energy_stored(randint(0, $body->energy_capacity));
    my $arr = rand_perc(scalar @food);
    for (0..(scalar @food - 1)) {
      $body->{$food[$_]}(randint(0, int($body->food_capacity * $arr->[$_]/100) ));
    }
    $arr = rand_perc(scalar @ore);
    for (0..(scalar @ore - 1)) {
      $body->{$ore[$_]}(randint(0, int($body->ore * $arr->[$_]/100) ));
    }
  }
  $body->update({
    needs_recalc                => 1,
  });
}

sub rand_perc {
  my ($num) = @_;

  my @arr;
  for (1..100) {
    $arr[randint(0,$num)]++;
  }
  return \@arr;
}

sub bhg_change_type {
  my ($body, $params) = @_;
print "Changing to type $params->{newtype}\n";
  my $class = $body->class;
  my $btype = $body->get_type;
  if ($btype eq 'asteroid') {
    confess [1009, "We can't change the type of that body"];
  }
  elsif ($btype eq 'gas giant') {
    confess [1009, "We can't change the type of that body"];
  }
  elsif ($btype eq 'habitable planet') {
    if ($params->{newtype} >= 1 and $params->{newtype} <= 20) {
      $class = 'Lacuna::DB::Result::Map::Body::Planet::P'.$params->{newtype};
    }
    else {
      confess [1009, 'Tring to change to a forbidden type!\n'];
    }
  }
  else {
    confess [1009, "We can't change the type of that body"];
  }
  $body->update({
    needs_recalc                => 1,
    class                       => $class,
    usable_as_starter_enabled   => 0,
  });
}

sub bhg_size {
  my ($building, $body, $bruce) = @_;
  print "Changing size\n";
  my $current_size = $body->size;
  my $btype = $body->get_type;
  if ($btype eq 'asteroid') {
    if ($bruce == -1) {
      $current_size -= int($building->level/10);
      $current_size = 1 if ($current_size < 1);
    }
    elsif ($bruce == 1) {
      if ($current_size >= 10) {
        $current_size++ if (randint(1,5) < 2);
      }
      else {
        $current_size += int($building->level/10);
        $current_size = 10 if ($current_size > 10);
      }
    }
    else {
      $current_size += randint(1,5) - 3;
      $current_size = 1 if ($current_size < 1);
    }
  }
  elsif ($btype eq 'gas giant') {
    confess [1009, "We can't change the sizes of that body"];
  }
  elsif ($btype eq 'habitable planet') {
    if ($bruce == -1) {
      $current_size -= $building->level;
      $current_size = 30 if ($current_size < 30);
    }
    elsif ($bruce == 1) {
      if ($current_size >= 65) {
        $current_size++ if (randint(1,5) < 2);
        $current_size = 69 if ($current_size > 69);
      }
      else {
        $current_size += $building->level;
        $current_size = 65 if ($current_size > 65);
      }
    }
    else {
      $current_size += randint(1,5) - 3;
      $current_size = 30 if ($current_size < 30);
    }
  }
  else {
    confess [1009, "We can't change the sizes of that body"];
  }
  $body->update({
    needs_recalc                => 1,
    size                        => $current_size,
    usable_as_starter_enabled   => 0,
  });
}

sub bhg_tasks {
  my ($building) = @_;
  my $day_sec = 60 * 60 * 24;
  my @tasks = (
    {
      name         => 'Make Planet',
      types        => ['asteroid'],
      wrongtype    => "You can only make a planet from an asteroid.",
      occupied     => 0,
      min_level    => 10,
      recovery     => int($day_sec * 90/$building->level),
      waste        => 1_000_000_000,
      fail_chance  => int(100 - $building->level * 2.5),
      side_chance  => 50,
    },
    {
      name         => 'Make Asteroid',
      types        => ['habitable planet', 'gas giant'],
      wrongtype    => "You can only make an asteroid from a planet.",
      occupied     => 0,
      min_level    => 10,
      recovery     => int($day_sec * 90/$building->level),
      waste        => 10_000_000,
      fail_chance  => int(100 - $building->level * 3),
      side_chance  => 10,
    },
    {
      name         => 'Increase Size',
      types        => ['habitable planet', 'asteroid'],
      wrongtype    => "You can only increase the sizes of habitable planets and asteroids.",
      occupied     => 1,
      min_level    => 20,
      recovery     => int($day_sec * 180/$building->level),
      waste        => 10_000_000_000,
      fail_chance  => int(100 - $building->level * 2),
      side_chance  => 65,
    },
    {
      name         => 'Change Type',
      types        => ['habitable planet'],
      wrongtype    => "You can only change the type of habitable planets.",
      occupied     => 1,
      min_level    => 30,
      recovery     => int($day_sec * 300/$building->level),
      waste        => 100_000_000,
      fail_chance  => int(100 - $building->level * 1.5),
      side_chance  => 90,
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

