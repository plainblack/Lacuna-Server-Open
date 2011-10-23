package Lacuna::RPC::Building::BlackHoleGenerator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Util qw(randint random_element);

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
  my $effect = {};
  my $return_stats = {};
  if ($building->is_working) {
    confess [1010, 'The Black Hole Generator is cooling down from the last use.']
  }
  my $target   = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_id);
  unless (defined $target) {
    confess [1002, 'Could not locate target.'];
  }
  my @tasks = bhg_tasks($building);
  my ($task) = grep { $task_name eq $_->{name} } @tasks;
  unless ($task) {
    confess [1002, 'Could not find task: '.$task_name];
  }
  unless ($building->level >= $task->{min_level}) {
    confess [1013, sprintf("You need a Level %d Black Hole Generator to do that",
                           $task->{min_level})];
  }
  my $btype = $target->get_type;
  unless ( grep { $btype eq $_ } @{$task->{types}} ) {
    confess [1009, $task->{wrongtype}];
  }
# TEST SETTINGS
  $task->{waste} = 1;
  $task->{recovery} = 10;
# TEST SETTINGS
  my $dist = sprintf "%7.2f", $building->body->calculate_distance_to_target($target)/100;
  my $range = $building->level * 10;
  unless ($dist < $range) {
    confess [1009, 'That body is too far away at '.$dist.' with a range of '.$range.'. '.$target_id."\n"];
  }
  unless ($body->waste_stored >= $task->{waste}) {
    confess [1011, 'Attempt to start Black Hole Generator without enough waste mass is not allowed.'];
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
        confess [1013, 'Your scientists refuse to destroy an asteroid with '.$count.' platforms.'];
      }
    }
    elsif (defined($target->empire)) {
      $body->add_news(100,
             sprintf('Scientists revolt against %s for trying to turn %s into an asteroid.',
                     $empire->name, $target->name));
      bhg_self_destruct($building);
      confess [1013, 'Your scientists refuse to destroy an inhabited body.'];
    }
  }
  $body->spend_waste($task->{waste})->update;
  $building->start_work({}, $task->{recovery})->update;
# Pass the basic checks
# Check for startup failure
  my $fail = randint(1,100) - (50 - sqrt( ($range - $dist) * (300/$range)) * 2.71);
  printf "Failure: %3d : Roll: %3.2f\n", $task->{fail_chance}, $fail;
  if (($task->{fail_chance} > $fail )) {
# Something went wrong with the start
    $fail = randint(1,20);
    if ($fail < 2) {
      $return_stats = bhg_self_destruct($building);
      $body->add_news(100,
             sprintf('%s finds a decimal point out of place.',
                     $empire->name));
    }
    elsif ($fail <  7) {
      $return_stats = bhg_decor($building, $body, -1);
      $body->add_news(100,
             sprintf('%s is wracked with changes.',
                     $body->name));
    }
    elsif ($fail < 12) {
      $return_stats = bhg_resource($body, -1);
      $body->add_news(100,
             sprintf('%s opens up a wormhole near their storage area.',
                     $body->name));
    }
    elsif ($fail < 17) {
      $return_stats = bhg_size($building, $body, -1);
      $body->add_news(100,
             sprintf('%s deforms after an expirement goes wild.',
                     $body->name));
    }
    elsif ($fail < 20) {
      $return_stats = bhg_random_make($building);
      $body->add_news(100,
             sprintf('Scientists on %s are concerned when their singularity has a malfunction.',
                     $body->name));
    }
    else {
      $return_stats = bhg_random_type($building);
      $body->add_news(100,
             sprintf('Scientists on %s are concerned when their singularity has a malfunction.',
                     $body->name));
    }
    $effect->{fail} = $return_stats;
  }
  else {
# We have a working BHG!
    if ($task->{name} eq "Make Planet") {
      $return_stats = bhg_make_planet($building, $target);
      $body->add_news(100,
                      sprintf('%s has expanded %s into a habitable world!',
                        $empire->name, $target->name));
    }
    elsif ($task->{name} eq "Make Asteroid") {
      $return_stats = bhg_make_asteroid($building, $target);
      $body->add_news(100, sprintf('%s has destroyed %s.', $empire->name, $target->name));
    }
    elsif ($task->{name} eq "Increase Size") {
      $return_stats = bhg_size($building, $target, 1);
      $body->add_news(100, sprintf('%s has expanded %s.', $empire->name, $target->name));
    }
    elsif ($task->{name} eq "Change Type") {
      $return_stats = bhg_change_type($target, $params);
      $body->add_news(100, sprintf('%s has gone thru extensive changes.', $target->name));
    }
    else {
      confess [552, "Internal Error"];
    }
    $effect->{target} = $return_stats;
#And now side effect time
    my $side = randint(1,100);
    print "Side: $task->{side_chance} Roll: $side\n";
    if ($task->{side_chance} > $side) {
      my $side_type = randint(0,99);
      if ($side_type < 25) {
        $return_stats = bhg_random_size($building);
      }
      elsif ($side_type < 40) {
        $return_stats = bhg_random_make($building);
      }
      elsif ($side_type < 50) {
        $return_stats = bhg_random_type($building);
      }
      elsif ($side_type < 76) {
        $return_stats = bhg_random_resource($building);
      }
      elsif ($side_type < 96) {
        $return_stats = bhg_random_decor($building);
      }
      else {
        $return_stats = bhg_size($building, $body, 0);
      }
      $effect->{side} = $return_stats;
    }
  }
  return {
    status => $self->format_status($empire, $body),
    effect => $effect,
  };
}

sub bhg_make_planet {
  my ($building, $body) = @_;
  my $class;
  my $size;
  my $old_class = $body->class;
  my $old_size  = $body->size;
  my $random = randint(1,100);
  if ($random < 6) {
    $class = 'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G'.randint(1,5);
    $size  = randint(70, 121);
  }
  else {
    $class = 'Lacuna::DB::Result::Map::Body::Planet::P'.randint(1,20);
    $size  = 30;
  }
 
  $body->update({
    class                       => $class,
    size                        => $size,
    needs_recalc                => 1,
    usable_as_starter_enabled   => 0,
  });
  $body->sanitize;
  return {
    old_class => $old_class,
    class     => $class,
    old_size  => $old_size,
    size      => $size,
    id        => $body->id,
    name      => $body->name,
  };
}

sub bhg_make_asteroid {
  my ($building, $body) = @_;
  my $old_class = $body->class;
  my $old_size  = $body->size;
  $body->update({
    class                       => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,21),
    size                        => int($building->level/5),
    needs_recalc                => 1,
    usable_as_starter_enabled   => 0,
    alliance_id => undef,
  });
  return {
    result    => "Made Asteroid",
    old_class => $old_class,
    class     => $body->class,
    old_size  => $old_size,
    size      => $body->size,
    id        => $body->id,
    name      => $body->name,
  };
}

sub bhg_random_make {
  my ($building) = @_;
  my $body = $building->body;
  my $return;
  my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
                  { zone => $body->zone, empire_id => undef, },
                  {rows => 1, order_by => 'rand()' }
                )->single;
  my $btype = $target->get_type;
  print $target->name, " is a ", $btype, " of ", substr($target->class, -3), ".\n";
  if ($btype eq 'habitable planet' or $btype eq 'gas giant') {
    $body->add_news(100, sprintf('%s has been destroyed!', $target->name));
    $return = bhg_make_asteroid($building, $target);
  }
  elsif ($btype eq 'asteroid') {
    my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->
                      search({asteroid_id => $target->id });
    unless ($platforms->next) {
      $body->add_news(100, sprintf('A new planet has appeared where %s had been!', $target->name));
      $return = bhg_make_planet($building, $target);
    }
    else {
      $return = {
        result => "Aborted making planet",
        id     => $target->id,
        name   => $target->name,
      };
    }
  }
  return $return;
}

sub bhg_random_type {
  my ($building) = @_;
  my $body = $building->body;
print "Random Type!\n";
  my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
                  { zone => $body->zone, empire_id => undef, },
                  {rows => 1, order_by => 'rand()' }
                )->single;
  my $btype = $target->get_type;
  my $return;
  if ($btype eq 'habitable planet') {
    my $params = { newtype => randint(1,20) };
    $body->add_news(100, sprintf('%s has gone thru extensive changes.', $target->name));
    $return = bhg_change_type($target, $params);
  }
  elsif ($btype eq 'asteroid') {
    my $params = { newtype => randint(1,21) };
    $body->add_news(100, sprintf('%s has gone thru extensive changes.', $target->name));
    $return = bhg_change_type($target, $params);
  }
  else {
    $return = {
      result => "Did not change type",
      id     => $target->id,
      name   => $target->name,
    };
  }
  return $return;
}

sub bhg_random_size {
  my ($building) = @_;
  my $body = $building->body;
print "Random Size!\n";
  my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
                  { zone => $body->zone, empire_id => undef },
                  {rows => 1, order_by => 'rand()' }
                )->single;
  my $return;
  my $btype = $target->get_type;
  if ($btype eq 'habitable planet') {
    $body->add_news(100, sprintf('%s has deformed.', $target->name));
    $return = bhg_size($building, $target, 0);
  }
  elsif ($btype eq 'asteroid') {
    $body->add_news(100, sprintf('%s has deformed.', $target->name));
    $return = bhg_size($building, $target, 0);
  }
  else {
    $return = {
      result => "Did not change size",
      id     => $target->id,
      name   => $target->name,
    };
  }
  return $return;
}

sub bhg_random_resource {
  my ($building) = @_;
  my $body = $building->body;
print "Random Resource!\n";
  my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
                  { zone => $body->zone, empire_id => { '!=' => undef} },
                  {rows => 1, order_by => 'rand()' }
                )->single;
  my $return;
  my $btype = $target->get_type;
  if ($btype eq 'habitable planet' or $btype eq 'gas giant') {
    $body->add_news(100, sprintf('A wormhole briefly appeared on %s.', $target->name));
    my $variance =  (randint(1,10) > 8) ? 1 : 0;
    $return = bhg_resource($target, $variance);
  }
  else {
    $return = {
      result => "No Resources Modified",
      id     => $target->id,
      name   => $target->name,
    };
  }
  return $return;
}

sub bhg_random_decor {
  my ($building) = @_;
  my $body = $building->body;
print "Random decor!\n";
  my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
                  { zone => $body->zone },
                  {rows => 1, order_by => 'rand()' }
                )->single;
  my $btype = $target->get_type;
  my $return = {
                 id        => $target->id,
                 name      => $target->name,
  };
  if ($btype eq 'habitable planet') {
    if ($target->empire_id) {
      $body->add_news(100, sprintf('The population of %s marvels at the new terrain.', $target->name));
    }
    else {
      $body->add_news(100, sprintf('Astromers claim that the surface of %s has changed.', $target->name));
    }
    my $variance =  (randint(1,10) > 8) ? 1 : 0;
    $return = bhg_decor($building, $target, $variance);
  }
  else {
    $return = {
      result => "No decorating",
      id     => $target->id,
      name   => $target->name,
      type   => $btype,
    };
  }
  return $return;
}

sub bhg_self_destruct {
  my ($building) = @_;
print "Boom!\n";
  my $body = $building->body;
  my $return = {
                 id        => $body->id,
                 name  => $body->name,
  };
  my $bombed = $body->buildings;
  my $bombs = $building->level;

  for my $cnt (1..$bombs) {
    my $placement = $bombed->search(
                       { class => { 'not in' => [
                    'Lacuna::DB::Result::Building::Permanent::Crater',
                    'Lacuna::DB::Result::Building::DeployedBleeder',
                ],
            },
        },
        {order_by => { -desc => ['efficiency', 'rand()'] }, rows=>1}
      )->single;
    last unless defined($placement);
    my $amount = randint(10, 100);
    $placement->spend_efficiency($amount)->update;
  }
  $body->needs_surface_refresh(1);
  $body->needs_recalc(1);
  $body->update;
  $building->update({class=>'Lacuna::DB::Result::Building::Permanent::Crater'});
  $return->{result} = "Black Hole Generator Destroyed";
  return $return;
}

sub bhg_decor {
  my ($building, $body, $variance) = @_;
print "Decor explosion on ", $body->name, "!\n";
  my @decor = qw(
                 Lacuna::DB::Result::Building::Permanent::Crater
                 Lacuna::DB::Result::Building::Permanent::Lake
                 Lacuna::DB::Result::Building::Permanent::RockyOutcrop
                 Lacuna::DB::Result::Building::Permanent::Grove
                 Lacuna::DB::Result::Building::Permanent::Sand
                 Lacuna::DB::Result::Building::Permanent::Lagoon
              );
  my $plant = randint(1, int($building->level/10)+1);
  my $planted = 0;
  my $now = DateTime->now;
  foreach my $cnt (1..$plant) {
    my ($x, $y) = eval { $body->find_free_space};
    unless ($@) {
        my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
            date_created => $now,
            class        => random_element(\@decor),
            x            => $x,
            y            => $y,
            level        => randint(1, int($building->level/5)),
            body_id      => $body->id,
        })->insert;
        $planted++;
    }
    else {
      last;
    }
  }
  if ($planted) {
    $body->needs_surface_refresh(1);
    $body->update;
  }
  return {
    id     => $body->id,
    name   => $body->name,
    result => "$planted items placed",
  };
}

sub bhg_resource {
  my ($body, $variance) = @_;
print "Resource shuffle $variance\n";
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
  my $return = {
    variance => $variance,
    id       => $body->id,
    name     => $body->name,
    result   => "Resource Shuffle",
  };
# Waste always reacts oddly
  my $waste_rnd = randint(1,5);
  if ($waste_rnd > 3) {
    $body->waste_stored($body->waste_capacity);
    $return->{waste} = "Filled";
  }
  elsif ($waste_rnd < 3) {
    $body->waste_stored(0);
    $return->{waste} = "Zero";
  }
  else {
    $body->waste_stored(randint(0, $body->waste_capacity));
    $return->{waste} = "Random";
  }
# Other resources
  if ($variance == 1) {
    $body->water_stored(randint($body->water_stored, $body->water_capacity));
    $body->energy_stored(randint($body->energy_stored, $body->energy_capacity));
    my $arr = rand_perc(scalar @food);
    my $food_stored = 0;
    for my $attrib (@food) { $food_stored += $body->$attrib; }
    my $food_room = $body->food_capacity - $food_stored;
    for (0..(scalar @food - 1)) {
      my $attribute = $food[$_];
      $body->$attribute(randint($attribute,
                              int($food_room * $arr->[$_]/100) ));
    }
    $arr = rand_perc(scalar @ore);
    my $ore_stored = 0;
    for my $attrib (@ore) { $ore_stored += $body->$attrib; }
    my $ore_room = $body->ore_capacity - $ore_stored;
    for (0..(scalar @ore - 1)) {
      my $attribute = $ore[$_];
      $body->$attribute(randint($attribute,
                              int($ore_room * $arr->[$_]/100) ));
    }
  }
  elsif ($variance == -1) {
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
      my $attribute = $food[$_];
      $body->$attribute(randint(0, int($body->food_capacity * $arr->[$_]/100) ));
    }
    $arr = rand_perc(scalar @ore);
    for (0..(scalar @ore - 1)) {
      my $attribute = $ore[$_];
      $body->$attribute(randint(0, int($body->ore_capacity * $arr->[$_]/100) ));
    }
  }
  $body->update({
    needs_recalc                => 1,
  });
  return $return;
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
  my $old_class = $class;
  my $btype = $body->get_type;
  if ($btype eq 'asteroid') {
    if ($params->{newtype} >= 1 and $params->{newtype} <= 21) {
      $class = 'Lacuna::DB::Result::Map::Body::Asteroid::A'.$params->{newtype};
    }
    else {
      confess [1013, 'Tring to change to a forbidden type!\n'];
    }
  }
  elsif ($btype eq 'gas giant') {
    confess [1013, "We can't change the type of that body"];
  }
  elsif ($btype eq 'habitable planet') {
    if ($params->{newtype} >= 1 and $params->{newtype} <= 20) {
      $class = 'Lacuna::DB::Result::Map::Body::Planet::P'.$params->{newtype};
    }
    else {
      confess [1013, 'Tring to change to a forbidden type!\n'];
    }
  }
  else {
    confess [1013, "We can't change the type of that body"];
  }
  $body->update({
    needs_recalc                => 1,
    class                       => $class,
    usable_as_starter_enabled   => 0,
  });
  return {
    result    => "Changed Type",
    old_class => $old_class,
    class     => $class,
    id        => $body->id,
    name      => $body->name,
  };
}

sub bhg_size {
  my ($building, $body, $variance) = @_;
  print "Changing size\n";
  my $current_size = $body->size;
  my $old_size     = $current_size;
  my $btype = $body->get_type;
  if ($btype eq 'asteroid') {
    if ($variance == -1) {
      $current_size -= randint(1, int($building->level/10)+1);
      $current_size = 1 if ($current_size < 1);
    }
    elsif ($variance == 1) {
      if ($current_size >= 10) {
        $current_size++ if (randint(1,5) < 2);
        $current_size = 20 if ($current_size > 20);
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
    confess [1013, "We can't change the sizes of that body"];
  }
  elsif ($btype eq 'habitable planet') {
    if ($variance == -1) {
      $current_size -= randint(1,$building->level);
      $current_size = 30 if ($current_size < 30);
    }
    elsif ($variance == 1) {
      if ($current_size >= 65) {
        $current_size++ if (randint(1,5) < 2);
        $current_size = 70 if ($current_size > 70);
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
    confess [1013, "We can't change the sizes of that body"];
  }
  $body->update({
    needs_recalc                => 1,
    size                        => $current_size,
    usable_as_starter_enabled   => 0,
  });
  return {
    result    => "Changed Size",
    old_size  => $old_size,
    size      => $current_size,
    id        => $body->id,
    name      => $body->name,
    type      => $btype,
  };
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
      min_level    => 15,
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
      min_level    => 25,
      recovery     => int($day_sec * 300/$building->level),
      waste        => 100_000_000,
      fail_chance  => int(100 - $building->level * 2),
      side_chance  => 90,
    },
  );
  return @tasks;
}

__PACKAGE__->register_rpc_method_names(qw(run_bhg));

no Moose;
__PACKAGE__->meta->make_immutable;

