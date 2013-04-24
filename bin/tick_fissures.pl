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

for my $body_id (sort keys %has_fissures) {
    my $body = $db->resultset('Map::Body')->find($body_id);
    out('Ticking Fissures on '.$body->name);
    my @fissures = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Permanent::Fissure');

    # Decrease the efficiency of all Fissure containment systems by an average of 4%
    # If a Fissure reaches 0% then it becomes unstable and upgrades a level and resets to 100% efficiency
    # When upgrading, it causes up to 15% damage to all energy producing buildings
    # When there is one Fissure at level 30 and 0% containment efficiency then another is spawned
    # When there are two Fissures at level 30 and 0% containment efficiency then the planet implodes.
    # When a new fissure is spawned, it first targets a BHG, then energy singularity, then any energy building
    #   and finally a spare space or a building at random (excluding the PCC).
    # The level of the second Fissure is the same level as the BHG (if there is one) otherwise it is level 1
    #
    my $fcnt_30;
    for my $fissure (@fissures) {
        out("Level ".$fissure->level." fissure at ".$fissure->x.",".$fissure->y." co-ordinates");
        my $damage = randint(2,6);
        if ($fissure->efficiency > 0) {
            $fissure->efficiency($fissure->efficiency - $damage);
        }
        if ($fissure->efficiency <= 0) {
            $fissure->efficiency(0);
            if ($fissure->level < 30) {
                $fissure->level($fissure->level + 1);
                $fissure->efficiency(100);

                # damage energy and BHG buildings.
                my @energy_buildings = grep {$_->class =~ /::Energy::/ || $_->class =~ /::Black/} @{$body->building_cache};
                foreach my $bld (@energy_buildings) {
                    my $rnd = randint(5,15);
                    $bld->efficiency($bld->efficiency - $rnd);
                    $bld->efficiency(0) if $bld->efficiency < 0;
                    $bld->update;
                }
                if ($body->empire_id) {
                    $body->empire->send_predefined_message(
                        tags        => ['Alert'],
                        filename    => 'fissure_damaged_energy.txt',
                        params      => [$body->name, $fissure->x,$fissure->y, $fissure->level],
                    );
                }
            }
        }
        out("    set to ".$fissure->efficiency."% containment efficiency");
        $fissure->is_working(0);
        $fissure->update;
        $fcnt_30++ if ($fissure->level >= 30);
        if ($fcnt_30 == 2) {  #If it's more than 2, then we're doomed anyway
            if ($body->empire_id) {
                $body->add_news(50, sprintf('Scientists have detected a critical mass of Illudium Q-36 on %s.',$body->name));
            }
            else {
                $body->add_news(50, sprintf('Neighbors of %s,  fear the planet will implode soon.',$body->name));
            }
        }
    }
    if ($body->empire_id) {
        $body->needs_recalc(1);
        $body->tick;
    }

    # get number of Fissures at 0% efficiency and maximum level
    my $max_fissures = grep { $_->efficiency == 0 and $_->level >= 30 } @fissures;
    if (($max_fissures == @fissures) or (scalar @fissures >= 3)) {
        if (scalar @fissures == 1) {
            out("    adding a second fissure!!!");
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
                        tags        => ['Alert'],
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
                #
                if ($body->empire_id) {
                    $body->empire->send_predefined_message(
                        tags        => ['Alert'],
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
        else {
            # If we get here. We have no option but to implode the planet!!
            
            # If it is an empire.
            if ($body->empire_id) {
                my $empire = $body->empire;

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
                        #
                        # Send the empire an email
                        $empire->send_predefined_message(
                            tags        => ['Colonization','Alert'],
                            filename    => 'fissure_capitol_moved.txt',
                            params      => [$new_capitol->name],
                        );
                    }
                    else {
                        # No more colonies, found a new empire on a remote planet
                        #
#                        my @zones = $db->resultset('Map::Star')->search(
#                            undef,
#                            { distinct => 1 })->get_column('zone')->all;
#                        @zones = grep {@_ !~ m/0/} @zones;
#                        my $zone = random_element(@zones);

                        my @bodies = $db->resultset('Map::Body')->search({
#                            'me.zone'           => $zone,
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
                            tags        => ['Colonization','Alert'],
                            filename    => 'fissure_capitol_moved.txt',
                            params      => [$new_capitol->name],
                        );
                    }
                }
                else {
                    # else it is 'just' a colony

                    # Send an email about the destruction
                    $empire->send_predefined_message(
                        tags        => ['Colonization','Alert'],
                        filename    => 'fissure_colony_destroyed.txt',
                        params      => [$body->name],
                    );
                }
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
                        tags        => ['Colonization','Alert'],
                        filename    => 'changed_size.txt',
                        params      => [$to_grab_mass->name, $size, $new_size],
                    );
                }
                last GASSY if (++$grown >= 5);
            }

            if ($body->in_neutral_area) {
                out("Skipping damage to other planets because origin in Neutral Area.");
                next;
            }
            # Damage planets in range (damage depends upon distance from the event)
            # get 10 closest planets
            my $closest = Lacuna->db->resultset('Map::Body')->search({
                -and => [
                    { empire_id => { '>'    => 1 }},
                    { empire_id => { '!='   => $body->id }},
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
                next if ($to_damage->in_neutral_area);
                next if ($to_damage->get_type eq 'space station');  # Since supply chains etc, will probably be damaged, they'll still be threatened.
                next unless ($to_damage->empire->date_created < DateTime->now->subtract(days => 60));

                # damage planet
                out("Damaging planet ".$to_damage->name." at distance ".$to_damage->get_column('distance'));

                my $distance = $to_damage->get_column('distance');
                # scale so a distance of 100 causes 1% damage and a distance of 0 causes 
                # an average of 50% damage
                my $distance = $to_damage->get_column('distance');
                my $damage  = int(100 - $distance);
                $damage = int($damage/2) if ($to_damage->get_type eq 'gas giant'); # Gas Giants are more resiliant or more spread out.
                $damage = 1 if $damage < 1;
                out("   Causing an average of $damage damage to each building");
                my @all_buildings = @{$to_damage->building_cache};
                out("   there are ".scalar(@all_buildings)." buildings");
                foreach my $building (@all_buildings) {
                    my $bld_damage = randint(1,$damage);
                    out("Damaging ".$building->name." by ${bld_damage}%");
                    $building->efficiency(int($building->efficiency - $bld_damage));
                    $building->efficiency(0) if $building->efficiency < 0;
                    $building->update;
                }
                
                $to_damage->empire->send_predefined_message(
                    tags        => ['Colonization','Alert'],
                    filename    => 'fissure_collateral_damage.txt',
                    params      => [$body->name, $to_damage->name],
                );
                if (++$damaged == 10) {
                    last DAMAGED;
                }
            }
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


