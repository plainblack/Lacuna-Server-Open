use lib '../../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use Lacuna;
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(ORE_TYPES);
use Lacuna::DB::Result::Building::Waste;


use DateTime;
use Time::HiRes;
use List::Util qw(max);
use GD::Image;

my $config  = Lacuna->config;
my $db      = Lacuna->db;

# This might need adjusting to get optimum results
my $fudge_factor    = 1.8;              # Can be used to adjust the number of stars/size of voids.
my $seed            = 3.14159;          # So we can reproduce the starmap
my $ore_stamps      = 4;                # How many pockets of high ore concentration are there for each ore
srand($seed);

my $lacunans_have_been_placed = 0;
my $mask;                               # masks to 'stamp' a pattern of star density on the density map
my $ore_mask;                           # mask used to create a pattern of ore density in TLE
my $density;                            # TLE is split into 90x90 chunks, each of which has a density of stars
my $ores;                               # 90x90 density of each type of ore.
my $density_factor;                     # a value used to help compute the number of stars
my $ore_asteroid;                       # hash of each asteroid type, and ore composition
my $ore_planet;                         # hash of each planet type, and ore composition
my $ore_gg;                             # hash of each Gas Giant type, and ore composition

# These will come from the lacuna config
my $min_x       = -1500;
my $max_x       = 1499;
my $min_y       = -1500;
my $max_y       = 1499;
my $max_stars   = 80000;

my $t = [Time::HiRes::tv_interval];
create_database();

# to test create db only, set env var, useful for testing db changes without
# rebuilding full star map, don't forget to change
# /data/Lacuna-Server/etc/lacuna.conf's db->dsn field to a new db first.
exit 0 if $ENV{CREATE_DB_ONLY};

setup();
#generate_stars();

#generate_png();

say "Time Elapsed: ".Time::HiRes::tv_interval($t);

exit;


sub create_database {
    say "Deploying database";
#    $db->deploy({ add_drop_table => 1 });
}

# Break the map down into chunks, so that there are 90x90 chunks
# Randomly choose a chunk and 'stamp' a density mask
# on it and the chunks adjacent to it, incrementing each chunks value
# by the level of the mask.
# With the right choice of numbers, this will produce voids and high
# density chunks which we can then populate with stars in proportion
# to the value of the chunk.
#
#
sub setup {
    say "Creating planet Ore data";

    my $test = Lacuna::DB::Result::Map::Body->new({});
    bless $test, 'Lacuna::DB::Result::Map::Body::Planet::P1';
    print "test = [$test]";

    foreach my $a (1..26) {
        my $name = "Lacuna::DB::Result::Map::Body::Asteroid::A$a";
        my $asteroid = $name->new();
        bless $asteroid, $name;

        foreach my $ore (ORE_TYPES) {
            $ore_asteroid->{"A$a"}{$ore} = $asteroid->$ore();
        }
    }
    foreach my $p (1..40) {
        next if $p == 33;
        my $name = "Lacuna::DB::Result::Map::Body::Planet::P$p";
        my $planet = $name->new();
        bless $planet, $name;
        foreach my $ore (ORE_TYPES) {
            $ore_planet->{"P$p"}{$ore} = $planet->$ore();
        }
    }
    foreach my $g (1..5) {
        my $name = "Lacuna::DB::Result::Map::Body::Planet::GasGiant::G$g";
        my $gas_giant = $name->new();
        bless $gas_giant, $name;
        foreach my $ore (ORE_TYPES) {
            $ore_gg->{"G$g"}{$ore} = $gas_giant->$ore();
        }
    }


    foreach my $p (1..40) {
    }

    say "Creating density map";
    # create some density masks

    foreach my $size (3,5,7) {
        for (my $y=1-$size; $y<$size; $y++) {
            for (my $x=1-$size; $x<$size; $x++) {
                my $dist = max(0, $size - int(sqrt($x * $x + $y * $y)));
                $mask->{$size}{$x}{$y} = $dist / 2;
            }
        }
    }
    # larger ore density mask
    for (my $y=-29; $y< 30; $y++) {
        for (my $x=-29; $x< 30; $x++) {
            my $dist = max(0, 30 - int(sqrt($x * $x + $y * $y)));
            $ore_mask->{$x}{$y} = $dist;
        }
    }
    
    # clear the density and ore distribution hashes
    for (my $x=0; $x<90; $x++) {
        for (my $y=0; $y<90; $y++) {
            $density->{"$x:$y"} = 0;
            foreach my $ore (ORE_TYPES) {
                $ores->{"$x:$y"}{$ore} = 0;
            }
        }
    }
    # 'stamp' the masks over the density grid a number of times
    # '220' is an arbitrary number that seems to work well.
    for (my $i=0; $i<220; $i++) {
        my $x = randint(0,89);
        my $y = randint(0,89);
        # chose a random mask.
        my $size = randint(1,3) * 2 + 1;
        for (my $delta_y = 1-$size; $delta_y < $size; $delta_y++) {
            for (my $delta_x = 1-$size; $delta_x < $size; $delta_x++) {
                my $p = $x + $delta_x;
                my $q = $y + $delta_y;
                if ($p >= 90) { $p -= 90; };
                if ($p < 0) { $p += 90; };
                if ($q >= 90) { $q -= 90; };
                if ($q < 0) { $q += 90; };
                $density->{"$p:$q"} += $mask->{$size}{$delta_x}{$delta_y};
            }
        }
    }

    # Create a density map for the different ores. This will determine the
    # type of planets to put in these chunks
    foreach my $ore (ORE_TYPES) {
        for (my $i=0; $i<$ore_stamps; $i++) {
            my $x = randint(0,89);
            my $y = randint(0,89);
            for (my $delta_y = -29; $delta_y < 30; $delta_y++) {
                for (my $delta_x = -29; $delta_x < 30; $delta_x++) {
                    my $p = $x + $delta_x;
                    my $q = $y + $delta_y;
                    if ($p >= 90) { $p -= 90; };
                    if ($p < 0) { $p += 90; };
                    if ($q >= 90) { $q -= 90; };
                    if ($q < 0) { $q += 90; };
                    $ores->{"$p:$q"}{$ore} += $ore_mask->{$delta_x}{$delta_y} * 2;
                }
            }
        }
    }

    # Print the ore types for each planet type
    foreach my $p (1..40) {
        next if $p==33;
        print "P$p :\t";
        foreach my $ore (sort keys %{$ore_planet->{"P$p"}}) {
            print $ore_planet->{"P$p"}{$ore}."\t";
        }
        print "\n";
    }


    # as a test, print the chunk map. We should see some voids '.' and some high density regions '*'
    # the map should also wrap left/right and top/bottom
    #
    $density_factor = 0;
    my $max_density = 0;
    for (my $y=0; $y<90; $y++) {
        for (my $x=0; $x<90; $x++) {
            my $d = $density->{"$x:$y"};
#            print $d > 9 ? "* " : $d == 0 ? ". " :$d." ";
            $density_factor += $d;
            $max_density = $d if $d > $max_density;
        }
#        print " ... $y\n";
    }

    # Print the density map for 'chromite'
    for (my $y=0; $y<90; $y++) {
        for (my $x=0; $x<90; $x++) {
            my $d = $ores->{"$x:$y"}{chromite};
#            print $d > 9 ? "* " : $d == 0 ? ". " :$d." ";
        }
#        print " ... $y\n";
    }
    # Print the ore density for zone 0|0
    for my $z ([0,30],[50,80],[39,39]) {
        my $x = $z->[0];
        my $y = $z->[1];
        say "$x:$y";
        for my $ore (ORE_TYPES) {
#            say "$ore\t".$ores->{"$x:$y"}{$ore};
        }
    }

    print "density_factor=$density_factor max_density=$max_density\n";
}

# now create the stars.
#
sub generate_stars {
    say "Generating stars";

    # 'density_factor' tells us the sum of all the chunks density.
    # from this we determine how many stars each density_factor units represent.
    my $stars_per_density = $max_stars / $density_factor;

    # sort the chunks, highest density first
    my @density_sorted = sort {$density->{$b} <=> $density->{$a}} keys %$density;
    my $star_id = 1;
    my $chunks_processed = 0;
    my $chunk_x = ($max_x - $min_x) / 90;
    my $chunk_y = ($max_y - $min_y) / 90;

    CHUNK:
    foreach my $ds (@density_sorted) {
        my $stars_per_chunk = int($density->{$ds} * $stars_per_density + $fudge_factor);

        # Calculate the TLE unit co-ordinates of this chunk.
        my ($p,$q)  = split(":", $ds);
        my $x_chunk_min = $min_x + $p * $chunk_x;
        my $x_chunk_max = int($x_chunk_min + $chunk_x);
        $x_chunk_min    = int($x_chunk_min);

        my $y_chunk_min = $min_y + $q * $chunk_y;
        my $y_chunk_max = int($y_chunk_min + $chunk_y);
        $y_chunk_min    = int($y_chunk_min);

        #say "x [$x_chunk_min][$x_chunk_max] y [$y_chunk_min][$y_chunk_max]"; 
        # see how many stars we can actually put in this chunk.
        my $retry = 0;
        my $stars_in_chunk = 0;
        STAR:
        while ($stars_in_chunk < $stars_per_chunk) {
            my $rand_x = randint($x_chunk_min, $x_chunk_max);
            my $rand_y = randint($y_chunk_min, $y_chunk_max);
            # Is this location suitable?
            #
            # Find all stars 'close' to this one
            if (room_for_star($p, $q, $rand_x, $rand_y)) {
                $stars_in_chunk++;
                $star_id++;
                last CHUNK if $star_id > $max_stars;
                $retry = 0;
            }
            else {
                if (++$retry > 30) {
                    # Give up, we can't find a place for another star in this chunk.
                    last STAR;
                }
            }
        }
        say "Stars ($star_id) in chunk [$p][$q] = $stars_in_chunk/$stars_per_chunk";
        $chunks_processed++;
    }
    if ($star_id < $max_stars) {
        say "not enough stars generated, try increasing 'fudge_factor'";
    }
    if ($chunks_processed < 90 * 90) {
        my $n = 90 * 90 - $chunks_processed;
        say "$n chunks left empty. You might decrease 'fudge_factor' but better to have some empty chunks rather than too few stars";
    }

}

# Check if this location is good for a star
# The linear distance between stars must be at least 6 units othewise the
# planets will overlap.
# Ensure that this star does not conflict with any other stars
# 
my $ds_stars;
sub room_for_star {
    my ($p, $q, $x, $y) = @_;

    # Some useful values, compute them out of the inner loop
    # 
    my $tle_width       = $max_x - $min_x;
    my $tle_height      = $max_y - $min_y;
    my $half_tle_width  = $tle_width/2;
    my $half_tle_height = $tle_height/2;
    #say "testing chunk [$p][$q]";

    # checking every other star is too computationally expensive
    # however we can just look at the adjacent chunks.
    CHUNK:
    foreach my $delta_chunk ([-1,1],[0,1],[1,1],[-1,0],[0,0],[1,0],[-1,-1],[0,-1],[1,-1]) {
        my $chunk_p = $p + $delta_chunk->[0];
        my $chunk_q = $q + $delta_chunk->[1];
        $chunk_p += 90 if $chunk_p < 0;
        $chunk_p -= 90 if $chunk_p >= 90;
        $chunk_q += 90 if $chunk_q < 0;
        $chunk_q -= 90 if $chunk_q >= 90;
        #say "chunk [$chunk_p][$chunk_q]";
        next CHUNK if not defined $ds_stars->{"$chunk_p:$chunk_q"};

        # check all the stars in this chunk
        foreach my $s (@{$ds_stars->{"$chunk_p:$chunk_q"}}) {
            # Check the distance, allowing for the TLE map wrap-around effect
            # 
            my $x_dist = $s->{x} - $x;
            $x_dist -= $tle_width if $x_dist > $half_tle_width;
            my $y_dist = $s->{y} - $y;
            $y_dist -= $tle_height if $y_dist > $half_tle_height;
            $x_dist = abs($x_dist);
            $y_dist = abs($y_dist);
            #say "checking [$x][$y] and [".$s->{x}."][".$s->{y}."] dist [$x_dist][$y_dist]";
            if ($x_dist < 6 and $y_dist < 6) {
                # we checked the linear distance, now check the pythagorean distance
                my $dist = sqrt($x_dist * $x_dist + $y_dist * $y_dist);
                if ($dist < 6) {
                    return;
                }
                # pythagorean distance is OK
            }
        }
    }
    push @{$ds_stars->{"$p:$q"}}, {x => $x, y => $y};
    return 1;
}

sub generate_png() {

    my $im = new GD::Image(3000,3000);
    my $white   = $im->colorAllocate(255,255,255);
    my $grey    =$im->colorAllocate(72,72,72);
    my $black   = $im->colorAllocate(0,0,0);
    my $star_colour = $im->colorAllocate(127,255,212);

    $im->filledRectangle(0,0,2999,2999,$grey);
    # draw the zone boundaries
    for (my $z=-3000; $z < 3000; $z += 250) {
        $im->line($z,-3000,$z,2999,$white);
        $im->line(-3000,$z,2999,$z,$white);
    }
    foreach my $ds (keys %$ds_stars) {
        my ($p,$q)  = split(":", $ds);
        foreach my $s (@{$ds_stars->{$ds}}) {
            my $x = $s->{x} + 1500;
            my $y = $s->{y} + 1500;
            $im->filledEllipse($x, $y, 5.5, 5.5, $star_colour);
        }
    }
    open(my $fh, '>',  'starmap.png') || die "Cannot create star image file $!";
    binmode $fh;
    print $fh $im->png;
    close $fh;
    
}

