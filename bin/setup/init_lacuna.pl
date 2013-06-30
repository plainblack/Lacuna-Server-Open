use lib '../../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use Lacuna;
use Lacuna::Util qw(randint);
use DateTime;
use Time::HiRes;
use List::Util qw(max);
use GD::Image;

my $config  = Lacuna->config;
my $db      = Lacuna->db;

# This might need adjusting to get optimum results
my $fudge_factor = 2;

my $lacunans_have_been_placed = 0;
my $mask;
my $density;
my @stars;
my $density_factor;

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
generate_stars();

generate_png();

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
    say "Creating density map";
    # create a density mask
    for (my $y=-4; $y<5; $y++) {
        for (my $x=-4; $x<5; $x++) {
            my $dist = max(0, 5 - int(sqrt($x * $x + $y * $y)));
            $mask->{$x}{$y} = $dist;
        }
    }
    for (my $x=0; $x<90; $x++) {
        for (my $y=0; $y<90; $y++) {
            $density->{"$x:$y"} = 0;
        }
    }
    # 'stamp' the mask over the density grid a number of times
    # '220' is an arbitrary number that seems to work well.
    for (my $i=0; $i<220; $i++) {
        my $x = randint(0,89);
        my $y = randint(0,89);

        for (my $delta_y = -4; $delta_y < 5; $delta_y++) {
            for (my $delta_x = -4; $delta_x < 5; $delta_x++) {
                my $p = $x + $delta_x;
                my $q = $y + $delta_y;
                if ($p >= 90) { $p -= 90; };
                if ($p < 0) { $p += 90; };
                if ($q >= 90) { $q -= 90; };
                if ($q < 0) { $q += 90; };
                $density->{"$p:$q"} += $mask->{$delta_x}{$delta_y};
            }
        }
    }

    # as a test, print the chunk map. We should see some voids '.' and some high density regions '*'
    # the map should also wrap left/right and top/bottom
    #
    $density_factor = 0;
    my $max_density = 0;
    for (my $y=0; $y<90; $y++) {
        for (my $x=0; $x<90; $x++) {
            my $d = $density->{"$x:$y"};
            print $d > 9 ? "* " : $d == 0 ? ". " :$d." ";
            $density_factor += $d;
            $max_density = $d if $d > $max_density;
        }
        print " ... $y\n";
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
        my $stars_per_chunk = int($density->{$ds} * $stars_per_density);
        $stars_per_chunk += $fudge_factor;
        # let's add a few stars to make up for chunks where we don't have enough room
#        say "ds [$ds] density [".$density->{$ds}."] stars_per_density [$stars_per_density] producing $star_id : $stars_per_chunk stars";

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
                push @stars, {x => $rand_x, y => $rand_y};
                $stars_in_chunk++;
#                say "Adding star [$star_id] to $rand_x:$rand_y";
                $star_id++;
                last CHUNK if $star_id > $max_stars;
                $retry = 0;
            }
            else {
                if (++$retry > 30) {
#                    say "RETRY EXCEEDED";
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
            my $x_dist = $s->{x} - $x;
            $x_dist -= $tle_width if $x_dist > $half_tle_width;
            my $y_dist = $s->{y} - $y;
            $y_dist -= $tle_height if $y_dist > $half_tle_height;
            $x_dist = abs($x_dist);
            $y_dist = abs($y_dist);
            #say "checking [$x][$y] and [".$s->{x}."][".$s->{y}."] dist [$x_dist][$y_dist]";
            if ($x_dist < 6 and $y_dist < 6) {
#                say "conflict [$x][$y] and [".$s->{x}."][".$s->{y}."]";
                # we checked the linear distance, no check the pythagorean distance
                my $dist = sqrt($x_dist * $x_dist + $y_dist * $y_dist);
                if ($dist < 6) {
    #                say "definately too close";
                    return;
                }
    #            say "pythagorean distance is OK";
            }
        }
    }
    #say "Add star to [$p][$q] [$x][$y]";
    push @{$ds_stars->{"$p:$q"}}, {x => $x, y => $y};
    return 1;
}

sub generate_png() {

    my $im = new GD::Image(3000,3000);
    my $white = $im->colorAllocate(255,255,255);
    my $black = $im->colorAllocate(0,0,0);
    $im->transparent($white);
    $im->interlaced('true');

    foreach my $ds (keys %$ds_stars) {
        my ($p,$q)  = split(":", $ds);
#        say "chunk $ds has ".scalar(@{$ds_stars->{$ds}})." stars";
        foreach my $s (@{$ds_stars->{$ds}}) {
            my $x = $s->{x} + 1500;
            my $y = $s->{y} + 1500;
            $im->filledEllipse($x, $y, 3, 3, $black);
        }
    }
    open(my $fh, '>',  'starmap.png') || die "Cannot create star image file $!";
    binmode $fh;
    print $fh $im->png;
    close $fh;
    
}

