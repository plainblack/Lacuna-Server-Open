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

use constant time_to_build => 500;

use constant food_consumption => 20;

use constant energy_consumption => 5;

use constant ore_consumption => 5;

use constant water_consumption => 30;

use constant waste_production => 20;

sub chance_of_glyph {
    my $self = shift;
    return $self->level;
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
  return 0 if ($self->level < 15);
  return ($self->level - 14);
}

sub run_excavators {
  my $self = shift;

  my $level = $self->level;
  my $empire = $self->body->empire;
# Do once for arch itself.  No chance of destroy or artifacts.
  my $result = $self->dig_it($self->body, $level, 1);
  $result->{id} = $self->id;
  my @results = ($result);
  if ($level > 14) {
    my $excavators = $self->excavators;
    while (my $excav = $excavators->next) {
      my $body = $excav->body;
      my $result;
      if ($body->empire_id) {
# Clean off the excav if planet gets settled.
        $result = {
          id => $excav->id,
          site => $body->name,
          outcome => "Destroyed",
          message => sprintf "Dig wiped out by new Colony from %s.",
                      $body->empire->name,
        };
      }
      else {
        $result = $self->dig_it($body, $level, 0);
        $result->{id} = $excav->id;
      }
#N19
      push @results, $result;
      if ($result->{outcome} eq "Destroyed") {
        $self->remove_excavator($excav);
      }
    }
  }
  my @report;
  for $result (sort { $a->{site} cmp $b->{site} } @results) {
    next if ($empire->skip_found_nothing       and $result->{outcome} eq "Nothing");
    next if ($empire->skip_excavator_artifact  and $result->{outcome} eq "Artifact");
    next if ($empire->skip_excavator_resources and $result->{outcome} eq "Resource");
    next if ($empire->skip_excavator_plan      and $result->{outcome} eq "Plan");
    next if ($empire->skip_excavator_glyph     and $result->{outcome} eq "Glyph");
    next if ($empire->skip_excavator_destroyed and $result->{outcome} eq "Destroyed");
    push @report, [
      $result->{site},
      $result->{outcome},
      $result->{message},
    ];
  }
  if (@report) {
    unshift @report, (['Site','Type','Result']);
    $empire->send_predefined_message(
      tags        => ['Excavator','Alert'],
      filename    => 'excavator_results.txt',
      params      => [ $self->body->id, $self->body->name ],
      attachments => { table => \@report},
    );
  }
  return 1;
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
      my $amount = randint(100 * $level, 1000 * $level);
      $self->body->add_type($type, $amount)->update;
      $result = {
        message => "Found $amount of $type.",
        outcome => "Resource",
      };
      $self->body->add_news(1,sprintf("%s uncovered a cache of %s on %s.",
                          $empire_name, $type, $body->name));
    }
    when ("plan") {
      my ($lvl, $plus, $name) = $self->found_plan($level);
      $result = {
        message => "Found level $lvl + $plus $name Plan.",
        outcome => "Plan",
      };
      $self->body->add_news(5,sprintf("%s uncovered a %s plan on %s.",
                          $empire_name, $name, $body->name));
    }
    when ("glyph") {
      my $glyph = $self->found_glyph($body);
      $result = {
        message => "Found a $glyph glyph.",
        outcome => "Glyph",
      };
      $self->body->add_news(5,sprintf("%s uncovered a %s glyph on %s.",
                          $empire_name, $glyph, $body->name));
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
        $self->body->add_news(20,sprintf("%s uncovered a rare %s plan on %s.",
                              $empire_name, $name, $body->name));
      }
    }
    when ("destroy") {
      if (randint(0,99) < 10) {
# This should give an excavator a
        my $message = random_element([
                        'Ph\'nglui Mglw\'nafh Cthulhu R\'lyeh wgah\'nagi fhtagn.',
                        'Klaatu Barada Ni*cough*',
                        'The brazen temple doors open...',
                        'It\'s full of stars'
                                    ]);
        $result = {
          message => $message,
          outcome => "Destroyed",
        };
        $self->body->add_news(10, $message);
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
  my $rand_cat = randint(0,19);
  my $lvl = 1;
  my $plus = 0;
  if ($rand_cat < 1) {
    $class = random_element($plan_types->{special});
    $plus = randint(0, int($level/7)) if (randint(0,19) < 1);
  }
  elsif ($rand_cat < 10) {
    $class = random_element($plan_types->{natural});
    $plus = randint(1, int($level/7)+1) if (randint(0,9) < 1);
  }
  else {
    $class = random_element($plan_types->{decor});
    $plus = randint(1, int($level/5)+1) if (randint(0,4) < 1);
  }
  my $plan = $self->body->add_plan($class, $lvl, $plus);

  return ($lvl, $plus, $class->name);
}

sub found_artifact {
  my ($self, $body, $level) = @_;
  
  my $plan_types = plans_of_type();
  my @buildings;
  my $buildings = $body->buildings;
  while (my $building = $buildings->next) {
    unless ( grep { $building->class eq $_ } @{$plan_types->{disallow}}) {
      push @buildings, $building;
    }
  }
  return (0,0,"Nothing") unless (@buildings);
  my $select = random_element(\@buildings);
  my $class; my $lvl; my $plus; my $name; my $destroy;
  if ($level > $select->level and randint(1, int(3 * $level/2)) >= $select->level) {
    $class = $select->class;
    $lvl   = 1;
    $plus  = int( ($select->level - 1) * 2/3); #Max doable would be 1+18
    $name  = $select->name;
    $destroy = 100;
  }
  elsif (randint(1,2) == 1) {
    $class = $select->class;
    $lvl   = 1;
    $plus  = 0;
    $name  = $select->name;
    $destroy = 10;
  }
  else {
    $class = $select->class;
    $lvl   = randint(1,$select->level); # Slight chance of getting a level 30 plan.
    $plus  = 0;
    $name  = $select->name;
    $destroy = 25;
  }
  $self->body->add_plan($class, $lvl, $plus);
  if ($select->level == 1 or randint(0,99) < $destroy) {
    $select->delete;
  }
  else {
    $select->level($select->level - 1);
    $select->update;
  }

  return ($lvl, $plus, $name);
}

sub found_glyph {
  my ($self, $body) = @_;

  my %ores;
  my $ore_total = 0;
  for my $ore (ORE_TYPES) {
    $ores{$ore} = $body->$ore;
    $ore_total += $ores{$ore};
  }
  my $base = 0;
  my $rnum = randint(1,$ore_total);
  my $glyph = "error";
  for my $ore (ORE_TYPES) {
    if ($rnum < $ores{$ore} + $base) {
      $glyph = $ore;
      last;
    }
    $base += $ores{$ore};
  }
  if ($glyph ne "error") {
    $self->body->add_glyph($glyph);
  }
  return $glyph;
}

sub can_you_dig_it {
  my ($self, $body, $level, $arch) = @_;

  my $mult = $arch + 1;
  my $plan  = ($level/5+1) * $mult; # 2.4-14%
  my $ore_total = 0;
  for my $ore (ORE_TYPES) {
     $ore_total += $body->$ore;
  }
  $ore_total = 10_000 if $ore_total > 10_000;
  my $glyph = int($mult * $level * $ore_total/10_000)+1; # 1-30% (2x if arch run)
  my $resource = 2 * $level; # 2-60%
  my $artifact = 0;
  if (!$arch && $body->buildings->count) {
    $artifact = 5;
  }
  my $destroy = $arch ? 0 : 1;
  $destroy += $artifact;
  my $most = $plan + $glyph + $artifact + $destroy;
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
    
  # excavator count for archaeology
  my $count = $self->excavators->count;
  unless ($on_arrival) {
    $count += Lacuna->db->resultset('Lacuna::DB::Result::Ships')
                ->search({type=>'excavator', task=>'Travelling',body_id=>$self->body_id})->count;
  }
  my $max_e = $self->max_excavators;
  if ($count >= $max_e) {
    confess [1009, 'Already at the maximum number of excavators allowed at this Archaeology level.'];
  }
    
# Allowed one per empire per body.
  $count = Lacuna->db->resultset('Lacuna::DB::Result::Excavators')
             ->search({ body_id => $body->id, empire_id => $self->body->empire->id })->count;
  unless ($on_arrival) {
    $count += Lacuna->db->resultset('Lacuna::DB::Result::Ships')
                ->search( {
                    type=>'excavator',
                    foreign_body_id => $body->id,
                    task=>'Travelling',
                    body_id=>$self->body_id
                 })->count;
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
        $body->add_news(70, sprintf('%s has uncovered a rare and ancient %s glyph on %s.',$empire->name, $ore, $body->name));
    }
};

sub make_plan {
    my ($self, $ids) = @_;
    unless (ref $ids eq 'ARRAY' && scalar(@{$ids}) < 5) {
        confess [1009, 'It is not possible to combine more than 4 glyphs.'];
    }

    my @glyph_names;
    my $glyphs_rs = $self->body->glyphs;
    foreach my $id (@{$ids}) {
        my $glyph = $glyphs_rs->find($id);
        confess [1002, 'You tried to combine a glyph you do not have.'] unless defined $glyph;
        push @glyph_names,$glyph->type;
    }

    my $plan_class = Lacuna::DB::Result::Plans->check_glyph_recipe(\@glyph_names);
    if (not $plan_class) {
        confess [1002, 'The glyphs specified do not fit together in that manner.'];
    }
    $glyphs_rs->search({ id => { in => $ids}})->delete;
    return $self->body->add_plan($plan_class, 1);
}

before 'can_downgrade' => sub {
  my $self = shift;
  my $ecount = $self->excavators->count;
  if ($ecount > 0 and $ecount > ($self->level - 15)) {
    confess [1013, 'You must abandon one of your Excavator Sites before you can downgrade the Archaeology Ministry.'];
  }
  if ($ecount > 0 && ($self->level -1) < 15 ) {
    confess [1013, 'You can not have any Excavator Sites if you are to downgrade your Archaeology Ministry below 15.'];
  }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
