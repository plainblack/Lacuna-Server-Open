use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Data::Dumper;
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date random_element);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

my %has_fissures = map { $_->body_id => 1 } $db->resultset('Building')->search({
    class => 'Lacuna::DB::Result::Building::Permanent::Fissure',
    })->all;

my $num_body = scalar keys %has_fissures;
out('Ticking '.$num_body.' bodies with fissures');


my %body_boom;
my %body_alert;

for my $body_id (sort keys %has_fissures) {
    my $body = $db->resultset('Map::Body')->find($body_id);
    my @fissures = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Permanent::Fissure');

# First check to see how many fissures we have active.
# If 3 or more fissures are at zero efficiency, the planet will explode.
# If 3 or more fissures on planet, rapidly degrade them.
# If less than 3 fissures:
# Decrease the efficiency of all Fissure containment systems by an average of 4%
# If a Fissure reaches 0% then it becomes unstable and upgrades a level and resets to 100% efficiency
# When upgrading, it causes up to 15% damage to all energy producing buildings
# If all fissures are at level 30 and 0% containment efficiency then another is spawned.
#
# When a new fissure is spawned, it first targets a BHG, then energy singularity, then any energy building
#   and finally a spare space or a building at random (excluding the PCC).
# The level of the second Fissure is the same level as the BHG (if there is one) otherwise it is level 1
    my $fissure_cnt = scalar @fissures;
    out(sprintf("Ticking %d Fissures on %s",$fissure_cnt,$body->name));
    if ($fissure_cnt >= 3) {
        my $f_at_0;
        for my $fissure (@fissures) {
            my $fiss_e = $fissure->efficiency;
            if ($fiss_e > 0) {
                $fissure->spend_efficiency(40);
                $f_at_0++ if ($fissure->efficiency == 0);
                $body_alert{$body_id} = {
                    range => 120,
                    type  => "critical",
                };
            }
            else {
                $fissure->efficiency(0);
                $f_at_0++;
            }
            $fissure->is_working(0);
            $fissure->update;
            out(sprintf("Level %02d:%03d/%02d fissure at %2d/%2d coordinates.",
                         $fissure->level, $fiss_e, $fissure->efficiency, $fissure->x, $fissure->y));
        }
        out(sprintf("%d of %d Fissures at critical.",$f_at_0, $fissure_cnt));
        if ($f_at_0 > 2) {
            $body_boom{$body_id} = 1;
        }
    }
    else {
        for my $fissure (@fissures) {
            my $damage = randint(1,10);
            if ($fissure->efficiency > 0) {
                $fissure->spend_efficiency($damage);
            }
            if ($fissure->efficiency <= 0) {
                $fissure->efficiency(0);
                if ($fissure->level < 30) {
                    out(sprintf("Level %02d:%03d fissures at %2d/%2d coordinates levels up.",
                         $fissure->level, $fissure->efficiency, $fissure->x, $fissure->y));
                    fissure_level($body, $fissure);
#Level fissure, Send minor alert $body_alert = level achieved.
                    my $range = ($fissure->level * 5) * $fissure_cnt;
                    if ($body_alert{$body_id}) {
                        $body_alert{$body_id}->{range} = $range
                            if ($body_alert{$body_id}->{range} < $range);
                    }
                    else {
                        $body_alert{$body_id} = {
                            range => $range,
                            type  => "level",
                        };
                    }
                }
                else {
                    out(sprintf("Level %02d:%03d fissures at %2d/%2d coordinates.",
                         $fissure->level, $fissure->efficiency, $fissure->x, $fissure->y));
                }
            }
            else {
                out(sprintf("Level %02d:%03d fissures at %2d/%2d coordinates.",
                         $fissure->level, $fissure->efficiency, $fissure->x, $fissure->y));
            }
            $fissure->is_working(0);
            $fissure->update;
        }
        if ($body->empire_id) {
            $body->needs_recalc(1);
            $body->needs_surface_refresh(1);
            $body->tick;
        }
        my $max_fissures = grep { $_->efficiency == 0 and $_->level >= 30 } @fissures;
        if ($max_fissures == $fissure_cnt) {
            fissure_spawn($body);
            my $range = 30 * $fissure_cnt;
            $body_alert{$body_id} = {
                range => $range,
                type  => "spawn",
            };
        }
    }
}
out(sprintf("We have explosive on %2d bodies", scalar keys %body_boom));
for my $body_id (sort keys %body_boom) {
    my $body = $db->resultset('Map::Body')->find($body_id);
    out('Exploding '.$body->name);
    delete $body_alert{$body_id} if ($body_alert{$body_id});
    fissure_explode($body);
}
out(sprintf("Warn people from %2d bodies", scalar keys %body_alert));
for my $body_id (sort keys %body_alert) {
    my $body = $db->resultset('Map::Body')->find($body_id);
#Alert empires once for each body within the alert range that had an event.
    fissure_alert($body, $body_alert{$body_id}->{range}, $body_alert{$body_id}->{type});
}

exit;

sub fissure_alert {
    my ($body, $range, $type)  = @_;

    $range =  25 if ($range <  25);
    $range = 120 if ($range > 120);
    my $minus_x = 0 - $body->x;
    my $minus_y = 0 - $body->y;
    my $alert = Lacuna->db->resultset('Map::Body')->search({
        -and => [
            {empire_id => { '!=' => 'Null' }}
        ],
    },{
        '+select' => [
            { ceil => \"pow(pow(me.x + $minus_x,2) + pow(me.y + $minus_y,2), 0.5)", '-as' => 'distance' },
        ],
        '+as' => [
            'distance',
        ],
        order_by    => 'distance',
    });
    my $number_to_alert = 25;;
    if ($type eq "level") {
        $number_to_alert = 10;;
    }
    elsif ($type eq "spawn") {
        $number_to_alert = 25;;
    }
    elsif ($type eq "critical") {
        $number_to_alert = 15;;
    }
    my %already;
    while (my $to_alert = $alert->next) {
        last if ($number_to_alert-- < 1);
        my $distance = $to_alert->get_column('distance');
        last if ($distance > $range);
        my $eid = $to_alert->empire_id;
        unless ($already{$eid} == 1) {
            $already{$eid} = 1;
            if ($type eq "spawn") {
                $to_alert->empire->send_predefined_message(
                    tags        => ['Fissure', 'Alert'],
                    filename    => 'fissure_alert_spawn.txt',
                    params      => [$body->x, $body->y, $body->name],
                );
            }
            elsif ($type eq "level") {
                $to_alert->empire->send_predefined_message(
                    tags        => ['Fissure', 'Alert'],
                    filename    => 'fissure_alert_level.txt',
                    params      => [$body->x, $body->y, $body->name],
                );
            }
            elsif ($type eq "critical") {
                $to_alert->empire->send_predefined_message(
                    tags        => ['Fissure', 'Alert'],
                    filename    => 'fissure_alert_critical.txt',
                    params      => [$body->x, $body->y, $body->name],
                );
            }
            else {
                out("Unknown Fissure alert for $body->name");
            }
        }
    }
}

sub fissure_spawn {
    my ($body) = @_;

    out("    adding fissure!!!");
# Then add a second fissure
# If there is a BHG then convert that!
    my $building = $body->get_building_of_class("Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator");
    my $fissure_level = 1;
    if ($building) {
        $fissure_level = $building->level > 0 ? $building->level : 1;
    }
    else {
# otherwise convert an energy building.
        my @buildings = grep {
            $_->class =~ /::Energy::/
        } @{$body->building_cache};
        $building = random_element(\@buildings);
    }
    if (not $building) {
# otherwise any random building (except the PCC or the Fissure)
        my @buildings = grep {
            ($_->x != 0 or $_->y != 0)            # anything except the PCC
            and ($_->class ne 'Lacuna::DB::Result::Building::Permanent::Fissure')   # Not a Fissure!
        } @{$body->building_cache};

        $building = random_element(\@buildings);                                       
    }
            
    if ($building) {
        my $now = DateTime->now;

        out("    Converted building ".$building->class." into a level $fissure_level Fissure!");
        if ($body->empire_id) {
            $body->empire->send_predefined_message(
                tags        => ['Fissure', 'Alert'],
                filename    => 'fissure_replaced_energy.txt',
                params      => [$body->name, $building->x,$building->y, $fissure_level],
            );
        }
        $building->update({
            level           => $fissure_level,
            class           => 'Lacuna::DB::Result::Building::Permanent::Fissure',
            efficiency      => 100,
            is_working      => 0,
            work_ends       => $now,
            is_upgrading    => 0,
            date_created    => $now,
        });
    }
    else {
# otherwise any free space
        my $x = randint(-5,5);
        my $y = randint(-5,5);
        if ($x == 0 and $y == 0) {
            $x = 1;
        }
        out("    using free plot $x,$y");

        $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
            x               => $x,
            y               => $y,
            class           => 'Lacuna::DB::Result::Building::Permanent::Fissure',
            level           => $fissure_level,
            is_upgrading    => 0,
        });
        $body->build_building($building,0,1);
# send email to empire and N19 news
        if ($body->empire_id) {
            $body->empire->send_predefined_message(
                tags        => ['Fissure', 'Alert'],
                filename    => 'fissure_spawned.txt',
                params      => [$body->name],
            );
        }
    }

    $body->add_news(50, sprintf('Scientists fear that %s is starting to tear itself apart.',$body->name));
    if ($body->empire_id) {
        $body->needs_recalc(1);
        $body->tick;
    }
}

sub fissure_level {
    my ($body, $fissure) = @_;

    $fissure->level($fissure->level + 1);
    $fissure->efficiency(100);

# damage energy and BHG buildings.
    my @energy_buildings = grep {$_->class =~ /::Energy::/ || $_->class =~ /::Black/} @{$body->building_cache};
    foreach my $bld (@energy_buildings) {
        my $rnd = randint(5,15);
        $bld->spend_efficiency($rnd);
        $bld->update;
    }
    if ($body->empire_id) {
        $body->empire->send_predefined_message(
            tags        => ['Fissure', 'Alert'],
            filename    => 'fissure_damaged_energy.txt',
            params      => [$body->name, $fissure->x,$fissure->y, $fissure->level],
        );
    }
}

sub fissure_explode {
    my ($body) = @_;
# If it is an empire.
    my $ename;
    if ($body->empire_id) {
        my $empire = $body->empire;
        $ename = $empire->name;

# If it is the empires home world
        if ($body->id == $empire->home_planet_id) {
            # check if there are other colonies we can move the capitol to
            my @colonies = $empire->planets;
            @colonies = grep {$_->id != $empire->home_planet_id} @colonies;
            if (@colonies) {
# Then move the capitol to a random colony
                my $new_capitol = random_element(\@colonies);
                $empire->home_planet_id($new_capitol->id);
                $empire->update;
# Send the empire an email
                $empire->send_predefined_message(
                    tags        => ['Colonization','Alert', 'Fissure'],
                    filename    => 'fissure_capitol_moved.txt',
                    params      => [$new_capitol->name],
                );
            }
            else {
# No more colonies, found a new empire on a remote planet
                my @bodies = $db->resultset('Map::Body')->search({
                    'me.empire_id'      => undef,
                    'stars.station_id'   => undef,
                    'me.class'          => { like => 'Lacuna::DB::Result::Map::Body::Planet::P%' },
                    'me.orbit'          => { between => [$empire->min_orbit, $empire->max_orbit] },
                },{
                    join                => 'stars',
                    rows                => 100,
                    order_by            => 'me.name',
                });
# Need error checking for no suitable body found.
                my $new_capitol = random_element(\@bodies);
                $empire->found($new_capitol);
                out($new_capitol->name.' new cap');
# Send an email with the new planet
                $empire->send_predefined_message(
                    tags        => ['Colonization','Alert', 'Fissure'],
                    filename    => 'fissure_capitol_moved.txt',
                    params      => [$new_capitol->name],
                );
            }
        }
        else {
# else it is 'just' a colony
# Send an email about the destruction
            $empire->send_predefined_message(
                tags        => ['Colonization','Alert', 'Fissure'],
                filename    => 'fissure_colony_destroyed.txt',
                params      => [$body->name],
            );
        }
        $empire->add_medal('fissure_explosion');
# Send out N19 news about the lost colony.
        $body->add_news(100, sprintf('A huge ripple in space-time was felt, caused by the implosion of %s, millions feared dead.',$body->name));
        $body->sanitize;
    }
# demolish the planet (convert it into an asteroid)
    out($body->name." at ".$body->x.",".$body->y." blows up.");
    $body->delete_buildings($body->building_cache);
    my $new_size = randint(1,10);
    $body->update({
        class                       => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,Lacuna::DB::Result::Map::Body->asteroid_types),
        size                        => $new_size,
        needs_recalc                => 1,
        usable_as_starter_enabled   => 0,
        alliance_id => undef,
    });
# Grow closest Gas Giants
    my $minus_x = 0 - $body->x;
    my $minus_y = 0 - $body->y;
    my $gas_giants = Lacuna->db->resultset('Map::Body')->search({
        -and => [
            { class     => { like => 'Lacuna::DB::Result::Map::Body::Planet::G%' }},
        ],
        },{
            '+select' => [
                { ceil => \"pow(pow(me.x + $minus_x,2) + pow(me.y + $minus_y,2), 0.5)", '-as' => 'distance' },
            ],
            '+as' => [
                'distance',
            ],
        order_by    => 'distance',
    });
    my $grown = 0;
    GASSY:
    while (my $to_grab_mass = $gas_giants->next) {
        my $size = $to_grab_mass->size;
        next if $size >= 121;
        my $new_size = $size + randint(1,5);
        $new_size = 121 if $new_size > 121;
        $to_grab_mass->size($new_size);
        $to_grab_mass->update;
        out("Growing ".$to_grab_mass->name." to ".$size.".");
        if ($to_grab_mass->empire) {
            $to_grab_mass->empire->send_predefined_message(
                tags        => ['Fissure','Colonization','Alert'],
                filename    => 'changed_size.txt',
                params      => [$to_grab_mass->name, $size, $new_size],
            );
        }
        last GASSY if (++$grown >= 5);
    }
    if ($body->in_neutral_area or $body->in_starter_zone) {
        out("Skipping damage to other planets because origin in Neutral or Starting Area.");
        return;
    }
# Damage planets in range (damage depends upon distance from the event)
# get 10 closest planets
    my $closest = Lacuna->db->resultset('Map::Body')->search({
        -and => [
            { empire_id => { '!=' => undef}},
        ],
    },{
        '+select' => [
            { ceil => \"pow(pow(me.x + $minus_x,2) + pow(me.y + $minus_y,2), 0.5)", '-as' => 'distance' },
        ],
        '+as' => [
            'distance',
        ],
        order_by    => 'distance',
    });
    my $damaged = 0;
    DAMAGED:
    while (my $to_damage = $closest->next) {
        next if ($to_damage->in_neutral_area or $to_damage->in_starter_zone);
        next if ($to_damage->get_type eq 'space station');  # Since supply chains etc, will probably be damaged, they'll still be threatened.
        next unless ($to_damage->empire->date_created < DateTime->now->subtract(days => 60));
# damage planet
        out("Damaging planet ".$to_damage->name." at distance ".$to_damage->get_column('distance'));

        my $distance = $to_damage->get_column('distance');
# scale so a distance of 100 causes 1% damage and a distance of 0 causes 
# an average of 50% damage
        my $distance = $to_damage->get_column('distance');
        if ($distance > 200) {
            out("At a distance of $distance, the debris is too dispersed. Only $damaged planets hit.");
            last;
        }
        my $damage  = int(100 - $distance);
        $damage = int($damage/2) if ($to_damage->get_type eq 'gas giant'); # Gas Giants are more resiliant or more spread out.
        my $citadel = $to_damage->get_building_of_class("Lacuna::DB::Result::Building::Permanent::CitadelOfKnope");
        if ($citadel) {
            my $reduction = 2 * $citadel->level;
            $damage -= $reduction;
            if ($damage < 1) {
                out("   Citadel causes all debris to bypass.");
                next;
            }
            out ("   Citadel reduces damage by $reduction.");
        }
        $damage = 1 if $damage < 1;
        out("   Causing an average of $damage damage to each building");
        my @all_buildings = @{$to_damage->building_cache};
        out("   there are ".scalar(@all_buildings)." buildings");
        foreach my $building (@all_buildings) {
            my $bld_damage = randint(1,$damage);
            out("Damaging ".$building->name." by ${bld_damage}%");
            $building->spend_efficiency($bld_damage);
            $building->update;
        }
        $to_damage->needs_recalc(1);
        $to_damage->needs_surface_refresh(1);
        $to_damage->tick;

        my $outrage;
        if ($ename) {
            $outrage = sprintf("We are currently investigating why %s let this happen to their people.", $ename);
        }
        else {
            $outrage = "Local empires are investigating who is responsible for this outrage."
        }
                
        $to_damage->empire->send_predefined_message(
            tags        => ['Fissure','Colonization','Alert'],
            filename    => 'fissure_collateral_damage.txt',
            params      => [$body->name, $to_damage->name, $outrage],
        );
        if (++$damaged == 10) {
            last DAMAGED;
        }
    }
}

###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


