package Lacuna::DB::Result::Building::Archaeology;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use Lacuna::Util qw(randint random_element);
use Clone qw(clone);
use feature 'switch';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Construction));
};

use constant max_instances_per_planet => 1;
use constant controller_class => 'Lacuna::RPC::Building::Archaeology';

use constant university_prereq => 11;

use constant image => 'archaeology';

use constant name => 'Archaeology Ministry';

use constant food_to_build => 210;

use constant energy_to_build => 240;

use constant ore_to_build => 210;

use constant water_to_build => 190;

use constant waste_to_build => 250;

use constant time_to_build => 480;

use constant food_consumption => 20;

use constant energy_consumption => 5;

use constant ore_consumption => 15;

use constant water_consumption => 25;

use constant waste_production => 20;

sub chance_of_glyph {
    my $self = shift;
    my $chance = ($self->level > $self->body->empire->university_level + 1) ?
                  $self->body->empire->university_level + 1 : $self->level;
    return $chance;
}

sub is_glyph_found {
    my $self = shift;
    return rand(100) <= $self->chance_of_glyph;
}

sub get_ores_available_for_processing {
    my ($self) = @_;
    my $body = $self->body;
    my %available;
    foreach my $type (ORE_TYPES) {
        my $stored = $body->type_stored($type);
        if ($stored >= 10_000) {
            $available{ $type } = $stored;
        }
    }
    return \%available;
}

sub max_excavators {
  my $self = shift;
  my $level = ($self->level > $self->body->empire->university_level + 1) ?
               $self->body->empire->university_level + 1 : $self->level;
  return 0 if ($level < 11);
  return ($level - 10);
}

sub run_excavators {
  my $self = shift;

  my $results;
  my $level = ($self->level > $self->body->empire->university_level + 1) ?
               $self->body->empire->university_level + 1 : $self->level;
  my $empire = $self->body->empire;
# Do once for arch itself.  No chance of destroy or artifacts.
  my $result = $self->dig_it($self->body, $level, 1);
  $result->{id} = $self->id;
  push @{$results}, $result;
  if ($level > 10) {
    my $excavators = $self->excavators;
    while (my $excav = $excavators->next) {
      my $body = $excav->body;
      my $result;
      my $new_colony = 0;
      if ($body->empire_id) {
# Clean off the excav if planet gets settled.
        $result = {
          id => $excav->id,
          site => $body->name,
          outcome => "Destroyed",
          message => sprintf "Dig wiped out by new Colony from %s.",
                      $body->empire->name,
        };
        $new_colony = 1;
      }
      else {
        $result = $self->dig_it($body, $level, 0);
        $result->{id} = $excav->id;
      }
      push @{$results}, $result;
      if ($result->{outcome} eq "Destroyed") {
        $self->remove_excavator($excav);
# If not a result from colony, send replacement excav if option is chosen.
        unless ($new_colony or $empire->dont_replace_excavator) {
          my $replacement = $self->replace_excav($body);
          push @{$results}, $replacement;
        }
      }
    }
  }
  my $report;
  for $result (sort { $a->{site} cmp $b->{site} } @{$results}) {
    next if ($empire->skip_found_nothing         and $result->{outcome} eq "Nothing");
    next if ($empire->skip_excavator_artifact    and $result->{outcome} eq "Artifact");
    next if ($empire->skip_excavator_resources   and $result->{outcome} eq "Resource");
    next if ($empire->skip_excavator_plan        and $result->{outcome} eq "Plan");
    next if ($empire->skip_excavator_glyph       and $result->{outcome} eq "Glyph");
    next if ($empire->skip_excavator_destroyed   and $result->{outcome} eq "Destroyed");
    next if ($empire->skip_excavator_replace_msg and $result->{outcome} eq "Replace");
    push @{$report}, [
      $result->{site},
      $result->{outcome},
      $result->{message},
    ];
  }
  if (defined($report)) {
    unshift @{$report}, (['Site','Type','Result']);
    $empire->send_predefined_message(
      tags        => ['Excavator','Alert'],
      filename    => 'excavator_results.txt',
      params      => [ $self->body->id, $self->body->name ],
      attachments => { table => $report},
    );
  }
  return 1;
}

sub replace_excav {
  my ($self, $body) = @_;

  my $replace_msg = {
        id => -1,
        site => $body->name,
        outcome => "Replace",
  };
# Check to see if excavs available
  my $avail = Lacuna->db->resultset('Lacuna::DB::Result::Ships')
                ->search({type=>'excavator', task=>'Docked',body_id=>$self->body_id});
  my $count = $avail->count;
  if ($count > 0) {
    my $ship;
    my $reason = "No Ship available";
    if ($ship = $avail->next) { # Just grab first one
      my $ok = eval { $ship->can_send_to_target($body) };
      if ($ok) {
        $reason = "";
      }
      else {
        $reason = $@;
      }
    }
    if ($reason) {
      if (ref $reason eq 'ARRAY') {
        $reason = join(":", @{$reason});
      }
      $replace_msg->{message} = sprintf("Fail : Could not send excavator: %s", $reason);
    }
    else {
      if (eval{$ship->send(target => $body)}) {
        $count--;
        $replace_msg->{message} = sprintf("Success : Excavator launched. %d left.", $count);
      }
      else {
        $replace_msg->{message} = "Fail : Target Failure";
      }
    }
  }
  else {
    $replace_msg->{message} = "Fail : No excavators to send";
  }
  return $replace_msg;
}

sub dig_it {
  my ($self, $body, $level, $arch) = @_;

  my $chances = $self->can_you_dig_it($body, $level, $arch);
  my $empire_name  = $self->body->empire->name;

  my $rnum = randint(0,99);
  my $base = 0;
  my $outcome = "nothing";
  for my $type (qw(destroy artifact plan glyph resource)) {
    if ($rnum < $chances->{$type} + $base) {
      $outcome = $type;
      last;
    }
    $base += $chances->{$type};
  }
  my $result;
  given ($outcome) {
    when ("resource") {
      my $type = random_element([ORE_TYPES, FOOD_TYPES, qw(water energy)]);
      my $amount = randint(10 * $level, 200 * $level);
      $self->body->add_type($type, $amount)->update;
      $result = {
        message => "Found $amount of $type.",
        outcome => "Resource",
      };
      if (randint(0,99) < 1) {
        $self->body->add_news(1,sprintf("%s uncovered a cache of %s on %s.",
                          $empire_name, $type, $body->name));
      }
    }
    when ("plan") {
      my ($lvl, $plus, $name) = $self->found_plan($level);
      $result = {
        message => "Found level $lvl + $plus $name Plan.",
        outcome => "Plan",
      };
      if (randint(0,99) < 1) {
        $self->body->add_news(10,sprintf("%s uncovered a %s plan on %s.",
                          $empire_name, $name, $body->name));
      }
    }
    when ("glyph") {
      my $glyph = $self->found_glyph($body);
      $result = {
        message => "Found a $glyph glyph.",
        outcome => "Glyph",
      };
      if (randint(0,99) < 1) {
        $self->body->add_news(1,sprintf("%s uncovered a %s glyph on %s.",
                          $empire_name, $glyph, $body->name));
      }
    }
    when ("artifact") {
      my ($lvl, $plus, $name) = $self->found_artifact($body, $level);
      if ($name eq "Nothing") {
        $result = {
          message => "No results found.",
          outcome => "Nothing",
        };
      }
      else {
        $result = {
          message => "Found level $lvl + $plus $name Plan.",
          outcome => "Artifact",
        };
        $self->body->add_news(10,sprintf("%s uncovered a rare %s plan on %s.",
                              $empire_name, $name, $body->name));
      }
    }
    when ("destroy") {
# Most destruction choices result in nothing found.
      if (randint(0,99) < 5) {
        my $message = random_element([
                        'Auntie Em, where\'s Toto? It\'s a twister! It\'s a twister!',
                        'Aw, there\'s something behind me, isn\'t there?',
                        'Dave, this conversation can serve no purpose anymore. Goodbye.',
                        'Did you notice anything weird a minute ago?',
                        'Doh!',
                        'Good. For a moment there, I thought we were in trouble.',
                        'Hasta la vista, baby',
                        'Hey, what does this red button do?',
                        'Hey! Watch this!',
                        'Houston.. we have a problem',
                        'I say we take off and nuke the site from orbit. It\'s the only way to be sure.',
                        'It\'s better to burn out, than to fade away',
                        'It\'s dead Jim.',
                        'It\'s just a harmless little bunny...',
                        'It\'s full of stars.',
                        'Just once, I wish we would encounter an alien menace that was\'t immune to bullets.',
                        'Looks like I picked the wrong week to stop drinking coffee.',
                        'Klaatu Barada Ni*cough*',
                        'No, Mr. Excav, I expect you to die.',
                        'Oh no, not again.',
                        'Oops? What oops? No oops!',
                        'Ph\'nglui Mglw\'nafh Cthulhu R\'lyeh wgah\'nagl fhtagn.',
                        'Push the button Max!',
                        'That\'s it man, game over man, game over!',
                        'The brazen temple doors open...',
                        'There are things in the mist.',
                        'They\'re coming for me now, and then they\'ll come for you!',
                        'They\'re here already! You\'re next! You\'re next, You\'re next...!',
                        'This is obviously some strange usage of the word safe that I wasn\'t previously aware of.',
                        'Trust me, I\'m trained to do this.',
                        'We have top men working on it now.',
                                    ]);
        $result = {
          message => "$message",
          outcome => "Destroyed",
        };
        $self->body->add_news(10, "$message");
      }
      else {
        $result = {
          message => "No results found.",
          outcome => "Nothing",
        };
      }
    }
    default {
      $result = {
        message => "No results found.",
        outcome => "Nothing",
      };
    }
  }
  $result->{id} = $self->id;
  $result->{site} = $body->name;
  return $result;
}

sub found_plan {
  my ($self, $level) = @_;

  my $plan_types = plans_of_type();
  my $class;
  my $rand_cat = randint(0,99);
  my $lvl = 1;
  my $plus = 0;
  if ($rand_cat < 3) {
    $class = random_element($plan_types->{special});
    if (randint(0,100) < int($level/3)) {
      $plus = randint(0, int($level/8));
      if ($level == 30 && $plus > 0) {
        $plus++;
      }
    }
  }
  elsif ($rand_cat < 80) {
    $class = random_element($plan_types->{natural});
    if (randint(0,100) < int($level/2)) {
      $plus = randint(0, int($level/6));
      if ($level == 30 && $plus > 0) {
        $plus++;
      }
    }
  }
  else {
    $class = random_element($plan_types->{decor});
    $plus = randint(1, int($level/5)+1) if (randint(0,100) < $level);
  }
  my $plan = $self->body->add_plan($class, $lvl, $plus);

  return ($lvl, $plus, $class->name);
}

sub found_artifact {
    my ($self, $body, $amlevel) = @_;
  
    my $plan_types = plans_of_type();
    my $artifacts;
    foreach my $building (@{$body->building_cache}) {
        unless ( grep { $building->class eq $_ } @{$plan_types->{disallow}}) {
            push @{$artifacts}, $building;
        }
    }
    return (0,0,"Nothing") unless (defined($artifacts));
    my $select = random_element($artifacts);
    my $class; my $plan_level; my $plus = 0; my $name; my $bld_destroy;
    if ($amlevel > $select->level and randint(1, int(3 * $amlevel/2)) >= $select->level) {
        $class = $select->class;
        $plan_level   = 1;
        $plus  = int( ($select->level - 1) * 3/5); #Max doable would be 1+17
        $name  = $select->name;
        $bld_destroy = 100;
    }
    elsif (randint(1,2) == 1) {
        $class = $select->class;
        if ($select->level == 1 and (randint(0,99) < 50) ) {
            $plan_level   = 0;
            $bld_destroy = 100;
            $name = "Nothing";
        }
        else {
            $plan_level   = 1;
            $bld_destroy = 10;
            $name  = $select->name;
        }
        $plus  = 0;
    }
    else {
        $class = $select->class;
        $plan_level   = randint(1,$amlevel); # Slight chance of getting a level 30 plan.
        $plan_level = $select->level if ($plan_level > $select->level);
        $plus  = 0;
        $name  = $select->name;
        $bld_destroy = 35;
    }
    $plan_level = 30  if ($plan_level > 30);
    $plus = 30 if ($plus > 30);
    $self->body->add_plan($class, $plan_level, $plus) if ($plan_level >= 1);
    if ($select->level == 1 or randint(0,99) < $bld_destroy) {
        $select->delete;
    }
    else {
        $select->level($select->level - 1);
        $select->update;
    }

    return ($plan_level, $plus, $name);
}

sub found_glyph {
  my ($self, $body) = @_;

  my $ores;
  my $ore_total = 0;
  for my $ore (ORE_TYPES) {
    $ores->{$ore} = $body->$ore;
    $ore_total += $ores->{$ore};
  }
  my $base = 0;
  my $rnum = randint(1,$ore_total);
  my $glyph = "error";
  for my $ore (ORE_TYPES) {
    if ($rnum <= $ores->{$ore} + $base) {
      $glyph = $ore;
      last;
    }
    $base += $ores->{$ore};
  }
  if ($glyph ne "error") {
    $self->body->add_glyph($glyph);
    $self->body->empire->add_medal($glyph.'_glyph');
  }
  return $glyph;
}

sub can_you_dig_it {
  my ($self, $body, $level, $arch) = @_;

  my $mult = $arch + 1;
  my $plan  = int($level/4 + 1);
  my $ore_total = 0;
  for my $ore (ORE_TYPES) {
     $ore_total += $body->$ore;
  }
  $ore_total = 10_000 if $ore_total > 10_000;
  my $glyph = int($mult * $level * $ore_total/20_000)+1; 
  my $resource = int(5/2 * $level);
  my $artifact = 0;
  if (!$arch && (scalar @{$body->building_cache})) {
    $artifact = 15;
  }
  my $destroy = $arch ? 0 : 5;
  $destroy += $artifact;
  my $most = $plan + $glyph + $artifact + $destroy;
# resource chance gets cut down if over 100%
  if ($most + $resource > 100) {
    $resource -= ($most + $resource - 100);
  }
  my $return = {
    plan => $plan,
    glyph => $glyph,
    resource => $resource,
    artifact => $artifact,
    destroy   => $destroy,
  };
  return $return;
}

sub plans_of_type {
  my $decor   = [qw(
       Lacuna::DB::Result::Building::Permanent::Beach1
       Lacuna::DB::Result::Building::Permanent::Beach2
       Lacuna::DB::Result::Building::Permanent::Beach3
       Lacuna::DB::Result::Building::Permanent::Beach4
       Lacuna::DB::Result::Building::Permanent::Beach5
       Lacuna::DB::Result::Building::Permanent::Beach6
       Lacuna::DB::Result::Building::Permanent::Beach7
       Lacuna::DB::Result::Building::Permanent::Beach8
       Lacuna::DB::Result::Building::Permanent::Beach9
       Lacuna::DB::Result::Building::Permanent::Beach10
       Lacuna::DB::Result::Building::Permanent::Beach11
       Lacuna::DB::Result::Building::Permanent::Beach12
       Lacuna::DB::Result::Building::Permanent::Beach13
       Lacuna::DB::Result::Building::Permanent::Crater
       Lacuna::DB::Result::Building::Permanent::Grove
       Lacuna::DB::Result::Building::Permanent::Lagoon
       Lacuna::DB::Result::Building::Permanent::Lake
       Lacuna::DB::Result::Building::Permanent::RockyOutcrop
       Lacuna::DB::Result::Building::Permanent::Sand
                )];
  my $natural = [qw(
       Lacuna::DB::Result::Building::Permanent::AlgaePond
       Lacuna::DB::Result::Building::Permanent::AmalgusMeadow
       Lacuna::DB::Result::Building::Permanent::BeeldebanNest
       Lacuna::DB::Result::Building::Permanent::DentonBrambles
       Lacuna::DB::Result::Building::Permanent::GeoThermalVent
       Lacuna::DB::Result::Building::Permanent::LapisForest
       Lacuna::DB::Result::Building::Permanent::MalcudField
       Lacuna::DB::Result::Building::Permanent::NaturalSpring
       Lacuna::DB::Result::Building::Permanent::Ravine
       Lacuna::DB::Result::Building::Permanent::Volcano
                )];
  my $special = [qw(
    Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator
    Lacuna::DB::Result::Building::Permanent::CitadelOfKnope
    Lacuna::DB::Result::Building::Permanent::CrashedShipSite
    Lacuna::DB::Result::Building::Permanent::GratchsGauntlet
    Lacuna::DB::Result::Building::Permanent::InterDimensionalRift
    Lacuna::DB::Result::Building::Permanent::KalavianRuins
    Lacuna::DB::Result::Building::Permanent::LibraryOfJith
    Lacuna::DB::Result::Building::Permanent::OracleOfAnid
    Lacuna::DB::Result::Building::Permanent::PantheonOfHagness
    Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites
                )];
  my $artifact = [qw(
       Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk
       Lacuna::DB::Result::Building::Permanent::GasGiantPlatform
       Lacuna::DB::Result::Building::Permanent::GreatBallOfJunk
       Lacuna::DB::Result::Building::Permanent::JunkHengeSculpture
       Lacuna::DB::Result::Building::Permanent::MetalJunkArches
       Lacuna::DB::Result::Building::Permanent::PyramidJunkSculpture
       Lacuna::DB::Result::Building::Permanent::SpaceJunkPark
       Lacuna::DB::Result::Building::Permanent::TerraformingPlatform
                )];
  my $disallow = [qw(
       Lacuna::DB::Result::Building::Permanent::EssentiaVein
       Lacuna::DB::Result::Building::Permanent::Fissure
       Lacuna::DB::Result::Building::Permanent::KasternsKeep
       Lacuna::DB::Result::Building::Permanent::MassadsHenge
       Lacuna::DB::Result::Building::Permanent::TheDillonForge
                )];
  return {
    decor    => $decor,
    natural  => $natural,
    special  => $special,
    artifact => $artifact,
    disallow => $disallow,
  };
}


sub excavators {
  my $self = shift;
  return Lacuna->db->resultset('Lacuna::DB::Result::Excavators')->search({ planet_id => $self->body_id });
}

sub can_add_excavator {
  my ($self, $body, $on_arrival) = @_;
    
  if (defined($body->empire_id)) {
    confess [1010, $body->name.' was colonized since we launched our excavator.'];
  }
  # excavator count for archaeology
  my $digging = $self->excavators->count;
  my $count = $digging;
  my $travel;
  unless ($on_arrival) {
    $travel = Lacuna->db->resultset('Lacuna::DB::Result::Ships')
                ->search({type=>'excavator', task=>'Travelling',body_id=>$self->body_id})->count;
    $count += $travel;
  }
  my $max_e = $self->max_excavators;
  if ($count >= $max_e) {
    my $string = "Max Excavators allowed at this Archaeology level is $max_e. You have $digging at sites, and $travel on their way.";
    confess [1009, $string];
  }
    
# Allowed one per empire per body.
  $count = Lacuna->db->resultset('Lacuna::DB::Result::Excavators')
             ->search({ body_id => $body->id, empire_id => $self->body->empire->id })->count;
  unless ($on_arrival) {
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')
                ->search( {
                    type=>'excavator',
                    foreign_body_id => $body->id,
                    task=>'Travelling',
                 });
    while (my $ship = $ships->next) {
      my $from = $ship->body;
      if ($from->empire->id == $self->body->empire->id) {
        $count++;
        last;
      }
    }
  }
  if ($count) {
    confess [1010, $body->name.' already has an excavator from your empire or one is on the way.'];
  }
  return 1;
}

sub add_excavator {
  my ($self, $body) = @_;
  Lacuna->db->resultset('Lacuna::DB::Result::Excavators')->new({
    planet_id   => $self->body_id,
    body_id     => $body->id,
    empire_id   => $self->body->empire->id,
  })->insert;
  return $self;
}

sub remove_excavator {
  my ($self, $excavator) = @_;
  $excavator->delete;
  return $self;
}

sub can_search_for_glyph {
    my ($self, $ore) = @_;
    unless ($self->level > 0) {
        confess [1010, 'The Archaeology Ministry is not finished building yet.'];
    }
    unless ($ore ~~ [ ORE_TYPES ]) {
        confess [1005, $ore.' is not a valid type of ore.'];
    }
    if ($self->is_working) {
        confess [1010, 'The Archaeology Ministry is already searching for a glyph.'];
    }
    unless ($self->body->type_stored($ore) >= 10_000) {
        confess [1011, 'Not enough '.$ore.' in storage. You need 10,000.'];
    }
    return 1;
}

sub search_for_glyph {
    my ($self, $ore) = @_;
    $self->can_search_for_glyph($ore);
    my $body = $self->body;
    $body->spend_ore_type($ore, 10_000);
    $body->add_waste(5000);
    $body->update;
    $self->start_work({
        ore_type    => $ore,
    }, 60*60*6)->update;
}

before finish_work => sub {
    my $self = shift;
    if ($self->is_glyph_found) {
        my $ore = $self->work->{ore_type};
        my $body = $self->body;
        $body->add_glyph($ore);
        my $empire = $body->empire;
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'glyph_discovered.txt',
            params      => [$body->id, $body->name, $ore],
            attachments => {
                image => {
                    title   => $ore,
                    url     => 'https://d16cbq0l6kkf21.cloudfront.net/assets/glyphs/'.$ore.'.png',
                }
            }
        );
        $empire->add_medal($ore.'_glyph');
        $body->add_news(30, sprintf('%s has uncovered a rare and ancient %s glyph on %s.',$empire->name, $ore, $body->name));
    }
};

sub make_plan {
    my ($self, $glyphs, $quantity) = @_;
    $quantity = 1 unless defined($quantity);
    unless (ref $glyphs eq 'ARRAY' && scalar(@{$glyphs}) < 5) {
      confess [1009, 'It is not possible to combine more than 4 glyphs.'];
    }

    my $plan_class;
    my $ids;

    # types
    my %count;
    if ( grep /\D/, @{$glyphs} ) {
        $plan_class = Lacuna::DB::Result::Plan->check_glyph_recipe($glyphs);
        if (not $plan_class) {
            confess [1002, 'The glyphs specified do not fit together in that manner.'];
        }

        $count{$_} += $quantity for @{$glyphs};
        for my $type ( sort keys %count ) {
            my $glyph = Lacuna->db->resultset('Lacuna::DB::Result::Glyph')->search({
                type    => $type,
                body_id => $self->body_id,
            })->single;
            unless (defined($glyph)) {
                confess [ 1002, "You don't have any glyphs of type $type."];
            }
            if ($glyph->quantity < $count{$type}) {
                confess [ 1002,
                    "You don't have $count{$type} glyphs of type $type you only have ".$glyph->quantity];
            }
        }
    }
    else {
      confess [1009, "Malformed glyph ARRAY."];
    }
    my $min_used = $quantity;
    for my $type (@{$glyphs}) {
        $count{$type} = $self->body->use_glyph($type, $quantity);
        $min_used = $count{$type} if ($min_used < $count{$type});
    }
# Check if all glyphs were used in case of timing issues.
    if ($min_used < $quantity) {
        for my $type (@{$glyphs}) {
            if ($min_used < $count{$type}) {
                $self->body->add_glyph($type, ($count{$type}));
            }
        }
    }
    confess [1002, "Glyphs used before they could be combined!"] if ($min_used == 0);

    my $plan = $self->body->add_plan($plan_class, 1, 0, $min_used);
    return $plan;
}

before delete => sub {
    my ($self) = @_;
    $self->excavators->delete_all;
};

before 'can_downgrade' => sub {
  my $self = shift;
  my $ecount = $self->excavators->count;
  if ($ecount > 0 and $ecount > ($self->level - 11)) {
    confess [1013, 'You must abandon one of your Excavator Sites before you can downgrade the Archaeology Ministry.'];
  }
  if ($ecount > 0 && ($self->level -1) < 11 ) {
    confess [1013, 'You can not have any Excavator Sites if you are to downgrade your Archaeology Ministry below 11.'];
  }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
