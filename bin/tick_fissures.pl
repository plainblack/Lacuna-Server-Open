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

out('Ticking fissures');
my %has_fissures = map { $_->body_id => 1 } $db->resultset('Building')->search({
    class => 'Lacuna::DB::Result::Building::Permanent::Fissure',
    })->all;

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
    for my $fissure (@fissures) {
        out("Fissure at ".$fissure->x.",".$fissure->y." co-ordinates");
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
                foreach $bld (@energy_buildings) {
                    my $rnd = randint(5,15);
                    $bld->efficiency($bld->efficiency - $rnd);
                    $bld->efficiency(0) if $bld->efficiency < 0;
                    $bld->update;
                }
                # Send email to empire and N19 news
                #
                #
                #
                # 
                
            }
        }
        out("    set to ".$fissure->efficiency."% containment efficiency");
        $fissure->is_working(0);
        $fissure->update;
    }
    if ($body->empire_id) {
        $body->needs_recalc(1);
        $body->tick;
    }

    # get number of Fissures at 0% efficiency and maximum level
    my $max_fissures = grep { $_->efficiency == 0 and $_->level == 30 } @fissures;
    if (($max_fissures == @fissures) or (scalar @fissures == 3)) {
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

                $building->update({
                    level           => $fissure_level,
                    class           => 'Lacuna::DB::Result::Building::Permanent::Fissure',
                    efficiency      => 100,
                    is_working      => 0,
                    work_ends       => $now,
                    is_upgrading    => 0,

                });
                out("    Converted building ".$building->class." into a level $fissure_level Fissure!");
                # send email to empire and N19 news
                #
                #
                #
                #
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
                    x       => $x,
                    y       => $y,
                    class   => 'Lacuna::DB::Result::Building::Permanent::Fissure',
                    level   => $fissure_level - 1,
                });
                $body->build_building($building);
                $building->finish_upgrade;
                # send email to empire and N19 news
                #
                #
                #
                #
                # 
            }


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
                        $body->sanitize;
                        
                        #
                        # Send the empire an email
                        # Put out news on N19
                    }
                    else {
                        # No more colonies, found a new empire on a remote planet
                        #
                        # Send an email with the new planet
                        # Send out N19 news about the survivors.
                    }
                }
                else {
                    # else it is 'just' a colony

                    # Send an email about the destruction

                    # Put something on N19
                }
            }
            # demolish the planet

            # Damage planets in range (damage depends upon distance from the event)

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


