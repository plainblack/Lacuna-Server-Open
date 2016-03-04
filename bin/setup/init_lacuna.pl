use lib '../../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use Lacuna;
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(ORE_TYPES);
use Lacuna::DB::Result::Empire;

use DateTime;
use Time::HiRes;
use List::Util qw(max);
use GD::Image;

# Generate a 'more natural' layout of stars where stars are clustered and there are voids
# Generate a distribution of ores within the expanse so that we have abundance and rarity
# This is achieved by splitting the expanse into chunks which are used to calculate star density and ore distribution
# Once we have the density of stars in each chunk we randomly place stars
# Once we have the relative amount of ore in each chunk we try to use a variation of the back-packers algorithm to place planets

# I have tried to use 'x' and 'y' to refer to co-ordinates in the TLE map
# 'p' and 'q' refer to co-ordinates in the (courser grained) chunk map

my $config  = Lacuna->config;
my $db      = Lacuna->db;

# These might need adjusting to get optimum results
my $fudge_factor    = 1.8;              # Increase to increase the number of stars and decrease the size of voids.
my $seed            = 3.14159;          # So we can reproduce the starmap.
my $ore_stamps      = 4;                # How many pockets of high ore concentration are there for each ore type.
srand($seed);
my $quick_test      = 0;                # For testing purposes, set to 0 for production

my $lacunans_have_been_placed = 0;
my $mask;                               # masks to 'stamp' a pattern of star density on the density map
my $ore_mask;                           # mask used to create a pattern of ore density in TLE
my $density;                            # TLE is split into chunks, each of which has a density of stars
my $ores;                               # chunks for density of each type of ore.
my $density_factor;                     # a value used to help compute the number of stars
my $body_ore;                           # ore composition for each body type
my $ds_stars;                           # The x,y co-ordinate of stars to place in each chunk


# Set up some variables which determine the size of the expanse
# 
my $map_size    = $config->get('map_size');
my ($map_min_x, $map_max_x) = @{$map_size->{x}};
my ($map_min_y, $map_max_y) = @{$map_size->{y}};
my $map_width   = ($map_max_x - $map_min_x);
my $map_height  = ($map_max_y - $map_min_y);

# max stars and chunk size depends on the area
my $max_stars   = int($map_width * $map_height / 112.5);
my $chunks      = int($map_width * 3 / 100);
my $odm_size    = int($chunks / 3);
say "We are going to generate $max_stars stars in chunks of $chunks and ore density mask size of $odm_size";

my $t = [Time::HiRes::tv_interval];

# This allows you to create up to 1.2M stars
open my $star_names, "<", "../../var/starnames.txt";

create_database();

# to test create db only, set env var, useful for testing db changes without
# rebuilding full star map, don't forget to change
# /data/Lacuna-Server-Open/etc/reboot.conf's db->dsn field to a new db first.
exit 0 if $ENV{CREATE_DB_ONLY};

setup();
generate_stars();
generate_stars_png();
generate_ores_png();

say "The distribution of stars can be found in the file starmap.png";
say "The distribution of each ore in the expanse can be found in ore_map.png files";
say "The remaining process can take some hours to run so check these png files first";
say "Then press enter if you wish to continue";
say "If you don't want to continue, but wish to try another seed value (currently $seed) then hit <ctrl>C";
my $input = <>;

update_database();

close $star_names;

say "Time Elapsed: ".int(Time::HiRes::tv_interval($t));
exit;


sub create_database {
    say "Deploying database";
    $db->deploy({ add_drop_table => 1 });
}

# Break the map down into chunks.
# Randomly 'stamp' the density mask over the chunks to create areas
# of high and low density which can then be used to distribute the
# stars and the ores.
#
sub setup {
    say "Creating planet Ore data";

    # Read the default ore values for each planet/asteroid/GG type
    foreach my $a (1..26) {
        my $name = "Lacuna::DB::Result::Map::Body::Asteroid::A$a";
        my $body = $name->new();
        # this is a bit of a cludge!
        bless $body, $name;

        foreach my $ore (ORE_TYPES) {
            $body_ore->{"A$a"}{$ore} = $body->$ore();
        }
    }
    foreach my $p (1..40) {
        next if $p == 33;
        my $name = "Lacuna::DB::Result::Map::Body::Planet::P$p";
        my $body = $name->new();
        bless $body, $name;
        foreach my $ore (ORE_TYPES) {
            $body_ore->{"P$p"}{$ore} = $body->$ore();
        }
    }
    foreach my $g (1..5) {
        my $name = "Lacuna::DB::Result::Map::Body::Planet::GasGiant::G$g";
        my $body = $name->new();
        bless $body, $name;
        foreach my $ore (ORE_TYPES) {
            $body_ore->{"G$g"}{$ore} = $body->$ore();
        }
    }

    # Normalize ore for each planet type to sum to 100
    foreach my $p (sort keys %$body_ore) {
        my $max = 0;
        foreach my $ore (keys %{$body_ore->{$p}}) {
            $max += $body_ore->{$p}{$ore};
        }
        foreach my $ore (keys %{$body_ore->{$p}}) {
            $body_ore->{$p}{$ore} = int($body_ore->{$p}{$ore} * (100 / $max) + 0.5);
        }
    }

    say "Creating star density map";
    # Create some different sized density masks
    foreach my $size (3,5,7) {
        for (my $v=1-$size; $v<$size; $v++) {
            for (my $u=1-$size; $u<$size; $u++) {
                my $dist = max(0, $size - int(sqrt($u * $u + $v * $v)));
                $mask->{$size}{$u}{$v} = $dist / 2;
            }
        }
    }
    # A larger ore density mask
    for (my $v=1-$odm_size; $v< $odm_size; $v++) {
        for (my $u=1-$odm_size; $u< $odm_size; $u++) {
            my $dist = max(0, $odm_size - int(sqrt($u * $u + $v * $v)));
            $ore_mask->{$u}{$v} = $dist;
        }
    }
    
    # clear the density and ore distribution hashes
    for (my $p=0; $p<$chunks; $p++) {
        for (my $q=0; $q<$chunks; $q++) {
            $density->{"$p:$q"} = 0;
            foreach my $ore (ORE_TYPES) {
                $ores->{$p}{$q}{$ore} = 0;
            }
        }
    }
    # 'stamp' the masks over the density grid a number of times
    # '220' is an arbitrary number that seems to work well to
    # create a 'natural' distribution of stars
    #
    for (my $i=0; $i<220; $i++) {
        my $x = randint(0,$chunks-1);
        my $y = randint(0,$chunks-1);
        # chose a random mask.
        my $size = randint(1,3) * 2 + 1;
        for (my $delta_y = 1-$size; $delta_y < $size; $delta_y++) {
            for (my $delta_x = 1-$size; $delta_x < $size; $delta_x++) {
                my $p = $x + $delta_x;
                my $q = $y + $delta_y;
                if ($p >= $chunks) { $p -= $chunks; };
                if ($p < 0) { $p += $chunks; };
                if ($q >= $chunks) { $q -= $chunks; };
                if ($q < 0) { $q += $chunks; };
                $density->{"$p:$q"} += $mask->{$size}{$delta_x}{$delta_y};
            }
        }
    }

    # Create a density map for the different ores. This will determine the
    # type of planets to put in these chunks
    foreach my $ore (ORE_TYPES) {
        for (my $i=0; $i<$ore_stamps; $i++) {
            my $x = randint(0,$chunks-1);
            my $y = randint(0,$chunks-1);
            for (my $delta_y = -29; $delta_y < 30; $delta_y++) {
                for (my $delta_x = -29; $delta_x < 30; $delta_x++) {
                    my $p = $x + $delta_x;
                    my $q = $y + $delta_y;
                    if ($p >= $chunks) { $p -= $chunks; };
                    if ($p < 0) { $p += $chunks; };
                    if ($q >= $chunks) { $q -= $chunks; };
                    if ($q < 0) { $q += $chunks; };
                    $ores->{$p}{$q}{$ore} += $ore_mask->{$delta_x}{$delta_y} * 2;
                }
            }
        }
    }

    # Normalize each chunk so that the ores sum to 100
    $density_factor = 0;
    for (my $q=0; $q<$chunks; $q++) {
        for (my $p=0; $p<$chunks; $p++) {
            $density_factor += $density->{"$p:$q"};
            my $sum = 0;
            foreach my $ore (ORE_TYPES) {
                $sum += $ores->{$p}{$q}{$ore};
            }
            foreach my $ore (ORE_TYPES) {
                $ores->{$p}{$q}{$ore} *= (100 / $sum);
            }
        }
    }
}

# Now create the planets and put the stars and planets into the database
#
sub update_database {
    say "Generating planets";

    if ($quick_test) {
        say "WARNING: Only doing a small test. Not for production!";
        update_database_chunk(0,0,0);
    }
    else {
        for (my $p=0; $p<$chunks; $p++) {
            for (my $q=0; $q<$chunks; $q++) {
                update_database_chunk($p,$q,0);
            }
        }
    }
    # Create Lacuna Expanse Corp systems
    # Re-use chunk 0:0, it is not significant
    #
    $ds_stars->{'0:0'} = [];
    push @{$ds_stars->{"0:0"}}, {x => 0, y => 0};
    push @{$ds_stars->{"0:0"}}, {x => 0, y => 6};
    push @{$ds_stars->{"0:0"}}, {x => 6, y => 3};
    push @{$ds_stars->{"0:0"}}, {x => 6, y => -3};
    push @{$ds_stars->{"0:0"}}, {x => 0, y => -6};
    push @{$ds_stars->{"0:0"}}, {x => -6, y => -3};
    push @{$ds_stars->{"0:0"}}, {x => -6, y => 3};

    # Create the lacunans somewhere in this system
    update_database_chunk(0,0,1);

}

# Put the stars and bodies for a single chunk
#
sub update_database_chunk {
    my ($p,$q, $create_lacunan) = @_;

    # Relative numbers of planets for this chunk.
    my $body_numbers = planets_for_chunk($p,$q);
    my $total_bodies = 0;
    map { $total_bodies += $body_numbers->{$_} } keys %$body_numbers;

    if (not defined $ds_stars->{"$p:$q"}) {
        say "Empty chunk!";
        return;
    }
    say "Adding bodies to chunk $p:$q total_bodies=$total_bodies";
    # all the stars for this chunk.
    my @stars_xy = @{$ds_stars->{"$p:$q"}};
    foreach my $star_xy (@stars_xy) {
        my $x = $star_xy->{x};
        my $y = $star_xy->{y};
        my $name = get_star_name();

        add_star_system({
            x               => $x, 
            y               => $y,
            name            => $name,
            body_numbers    => $body_numbers,
            total_bodies    => $total_bodies,
            create_lacunan  => $create_lacunan,
        });
    }
}

# Add a single star system
#
sub add_star_system {
    my ($args) = @_;

    my $x = $args->{x};
    my $y = $args->{y};
    my $name = $args->{name};
    my $total_bodies    = $args->{total_bodies};
    my $body_numbers    = $args->{body_numbers};
    my $create_lacunan  = $args->{create_lacunan};

    my @star_colors = (qw(magenta red green blue yellow white));
    my $orbit_deltas = {
        1   => [1,  2],
        2   => [2,  1],
        3   => [2,  -1],
        4   => [1,  -2],
        5   => [-1, -2],
        6   => [-2, -1],
        7   => [-2, 1],
        8   => [-1, 2],
    };
    say "Adding star $name to $x:$y";

    my $star = $db->resultset('Map::Star')->new({
        name        => $name,
        color       => $star_colors[rand(scalar(@star_colors))],
        x           => $x,
        y           => $y,
    });
    $star->set_zone_from_xy;
    $star->insert;

    # Add bodies to this star
    #
    for my $orbit (1..8) {
        my $name = $star->name." ".$orbit;
        if (randint(1,100) <= 10) {
            # 10% chance of no body in this orbit
            say "\tNo body at $name!";
        }
        else {
            my ($x_delta, $y_delta) = @{$orbit_deltas->{$orbit}};
            my $x_body = $x + $x_delta;
            my $y_body = $y + $y_delta;

            my $body_i = randint(0, $total_bodies - 1);
            my $i = 0;
            my $body_name = 'A1';
            BODY:
            foreach my $bn (sort keys %$body_numbers) {
                $body_name = $bn;
                last BODY if $i >= $body_i;
                $i += $body_numbers->{$body_name};
            }

            # convert body_name into a Class
            my $add_features;
            my $class = 'Lacuna::DB::Result::Map::Body::';
            my $size = 0;
            if ($body_name =~ m/^A/) {
                $class .= "Asteroid::$body_name";
                $size = randint(1,10);
            }
            if ($body_name =~ m/^P/) {
                $class  .= "Planet::$body_name";
                $size = randint(30,65);
                $add_features = 1;
            }
            if ($body_name =~ m/^G/) {
                $class .= "Planet::GasGiant::$body_name";
                $size = randint(70,121);
            }
            say "\t\tAdding body type $body_name named $name";
            my $body = $db->resultset('Map::Body')->create({
                name        => $name,
                orbit       => $orbit,
                x           => $x_body,
                y           => $y_body,
                zone        => $star->zone,
                star_id     => $star->id,
                class       => $class,
                size        => $size,
            });
            if ($add_features) {
                add_features($body);
            }
            if ($body_name =~ m/^P/ and $create_lacunan) {
                # create Lacunan home world (unless already done)
                create_lacunan_home_world($body);
            }
        }
    }
}

sub create_lacunan_home_world {
    my ($body) = @_;

    return if $lacunans_have_been_placed;

    $body->update({name=>'Lacuna'});
    say "\t\t\tMaking this the Lacunans home world.";
    my $empire = Lacuna->db->resultset('Empire')->new({
        id                      => 1,
        name                    => 'Lacuna Expanse Corp',
        date_created            => DateTime->now,
        stage                   => 'founded',
        status_message          => 'Will trade for Essentia.',
        password                => Lacuna::DB::Result::Empire->encrypt_password('secret56'),
        species_name            => 'Lacunan',
        species_description     => 'The economic deities that control the Lacuna Expanse.',
        min_orbit               => 1,
        max_orbit               => 7,
        manufacturing_affinity  => 1, # cost of building new stuff
        deception_affinity      => 7, # spying ability
        research_affinity       => 1, # cost of upgrading
        management_affinity     => 4, # speed to build
        farming_affinity        => 1, # food
        mining_affinity         => 1, # minerals
        science_affinity        => 1, # energy, propultion, and other tech
        environmental_affinity  => 1, # waste and water
        political_affinity      => 7, # happiness
        trade_affinity          => 7, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 7, # price and speed of colony ships, and planetary command center start level
    });
    $empire->insert;
    $empire->found($body);
    $lacunans_have_been_placed = 1;
}

sub add_features {
    my ($body) = @_;

    say "\t\tAdding features to body.";
    my $now = DateTime->now;
    foreach  my $x (-3, -1, 2, 4, 1) {
        my $chance = randint(1,100);
        my $y = randint(-5,5);
        if ($chance <= 5) {
            say "\t\t\tAdding lake.";
            $db->resultset('Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Building::Permanent::Lake',
                body_id         => $body->id,
            })->insert;
        }
        elsif ($chance > 45 && $chance <= 50) {
            say "\t\t\tAdding rocky outcropping.";
            $db->resultset('Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Building::Permanent::RockyOutcrop',
                body_id         => $body->id,
            })->insert;
        }
        elsif ($chance > 95) {
            say "\t\t\tAdding crater.";
            $db->resultset('Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Building::Permanent::Crater',
                body_id         => $body->id,
            })->insert;
        }
    }
}

sub get_star_name {

    # Get the next available starname
    STARNAME:
    while (my $name = <$star_names>) {
        chomp $name;
        next STARNAME if $name eq 'Lacuna';

        if ($db->resultset('Map::Star')->search({ name => $name })->count == 0 ) {
            return $name
        }
    }
    die "No more starnames!\n";
}


# Generate the list of bodies (and their relative quantity) to
# include in a chunk
#
# It attempts to select bodies and their quantity such that it closely
# approximates the distribution of ores in that chunk as calculated in
# the setup.
#
# Input the p and q co-ordinate of the chunk
# 
sub planets_for_chunk {
    my ($p, $q) = @_;
    say "Calculating bodies for chunk $p:$q";

    print "$p:$q\t\t";
    my $target_ores = $ores->{$p}{$q};
    foreach my $ore (ORE_TYPES) {
        print int($target_ores->{$ore})."\t";
    }
    print "\n";

    # counter for each body type
    my $body_qty;
    foreach my $body (keys %{$body_ore}) {
        $body_qty->{$body} = 0;
    }
    my $total_bodies = 0;           # Number of bodies added to the list
    my $best_sum = 999999999999999;

    while ($total_bodies < 100) {
        my $best_body   = '';
        my $best_found  = 0;

        # For each body, test the new sum of errors when increasing the number of that body by 1
        # Whichever body (if any) improves the sum the most, should be used.

        foreach my $body (keys %{$body_ore}) {
            my $sum = 0;
            foreach my $ore ( keys %$target_ores) {
                my $ore_sum = $body_ore->{$body}{$ore};
                foreach my $body (keys %$body_ore) {
                    $ore_sum += $body_ore->{$body}{$ore} * $body_qty->{$body};
                }
                $ore_sum /= ($total_bodies + 1);
                $sum += abs($target_ores->{$ore} - $ore_sum);
            }
            if ($sum < $best_sum) {
                $best_sum   = $sum;
                $best_body  = $body;
                $best_found = 1;
            }
        }

        if ($best_found) {
            # add in this planets ore
            $body_qty->{$best_body}++;
            $total_bodies++;
        }
        else {
            # double up all the existing body quantities.
            $total_bodies = 0;
            foreach my $body (keys %$body_ore) {
                $body_qty->{$body} *= 2;
                $total_bodies += $body_qty->{$body};
            }
        }
    }
    # Print the actual density
    print "actual\tqty\t";
    foreach my $ore (ORE_TYPES) {
        my $qty = 0;
        foreach my $body (keys %{$body_qty}) {
            $qty += $body_qty->{$body} * $body_ore->{$body}{$ore};
        }
        print int($qty / $total_bodies)."\t";
    }
    print "\n\n";
    return $body_qty;
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
    my $chunk_x = ($map_max_x - $map_min_x) / $chunks;
    my $chunk_y = ($map_max_y - $map_min_y) / $chunks;

    CHUNK:
    foreach my $ds (@density_sorted) {
        my $stars_per_chunk = int($density->{$ds} * $stars_per_density + $fudge_factor);

        # Calculate the TLE unit co-ordinates of this chunk.
        my ($p,$q)  = split(":", $ds);
        my $x_chunk_min = $map_min_x + $p * $chunk_x;
        my $x_chunk_max = int($x_chunk_min + $chunk_x);
        $x_chunk_min    = int($x_chunk_min);

        my $y_chunk_min = $map_min_y + $q * $chunk_y;
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
            # Leave a 'void' for the Lacuna Expanse Corp home worlds
            # at least 60 units of 0|0
            
            my $dist = sqrt($rand_x * $rand_x + $rand_y * $rand_y);
            if ($dist < 60) {
                say "Omitting star at $rand_x | $rand_y";
                $stars_in_chunk++;
                next STAR;
            }

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
        say "not enough stars generated, we recommend increasing the 'fudge_factor'";
    }
    if ($chunks_processed < $chunks * $chunks) {
        my $n = $chunks * $chunks - $chunks_processed;
        say "$n chunks left empty. You might decrease 'fudge_factor' but better to have some empty chunks rather than too few stars";
    }
}

# Check if this location is good for a star
# The linear distance between stars must be at least 6 units otherwise the
# planets will overlap.
# Ensure that this star does not conflict with any other stars
# 
# $ds_stars contains the x,y co-ordinate of all stars in a chunk, for use later
# 
sub room_for_star {
    my ($p, $q, $x, $y) = @_;

    # Some useful values, compute them out of the inner loop
    # 
    my $tle_width       = $map_max_x - $map_min_x;
    my $tle_height      = $map_max_y - $map_min_y;
    my $half_tle_width  = $tle_width/2;
    my $half_tle_height = $tle_height/2;
    #say "testing chunk [$p][$q]";

    # checking every other star is too computationally expensive
    # however we can just look at the adjacent chunks.
    CHUNK:
    foreach my $delta_chunk ([-1,1],[0,1],[1,1],[-1,0],[0,0],[1,0],[-1,-1],[0,-1],[1,-1]) {
        my $chunk_p = $p + $delta_chunk->[0];
        my $chunk_q = $q + $delta_chunk->[1];
        $chunk_p += $chunks if $chunk_p < 0;
        $chunk_p -= $chunks if $chunk_p >= $chunks;
        $chunk_q += $chunks if $chunk_q < 0;
        $chunk_q -= $chunks if $chunk_q >= $chunks;
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

#############################
# Image generation routines #
#############################

# Get next RGB colour
#
my $h = 0.123;
sub generate_colour {
    # golden ratio
    $h += 0.618033988749895;
    $h = $h - int($h);
    return convert_hsv_to_rgb($h, 0.99, 0.99);
}

# Convert colour HSV to RGB
#
sub convert_hsv_to_rgb {
    my ($h, $s, $v) = @_;

    my $hi  = int($h * 6);
    my $f   = $h * 6 - $hi;
    my $p   = $v * (1 - $s);
    my $q   = $v * (1 - $f * $s);
    my $t   = $v * (1 - (1 - $f) * $s);
    my ($r, $g, $b);
    ($r, $g, $b) = ($v, $t, $p) if $hi == 0;
    ($r, $g, $b) = ($q, $v, $p) if $hi == 1;
    ($r, $g, $b) = ($p, $v, $t) if $hi == 2;
    ($r, $g, $b) = ($p, $q, $v) if $hi == 3;
    ($r, $g, $b) = ($t, $p, $v) if $hi == 4;
    ($r, $g, $b) = ($v, $p, $q) if $hi == 5;
    return [int($r * 256), int($g * 256), int($b * 256)];
}


# Generate a png for each ore that shows it's distribution
#
sub generate_ores_png() {

    foreach my $ore (ORE_TYPES) {
        say "Generating ore distribution map for $ore";
        my $im = new GD::Image($map_width,$map_height);
        my $white       = $im->colorAllocate(255,255,255);
        my $grey        = $im->colorAllocate(72,72,72);
        my $black       = $im->colorAllocate(0,0,0);
        my $star_colour = $im->colorAllocate(127,255,212);
        my $colour      = generate_colour();
        my $ore_colour  = $im->colorAllocate(@$colour);

        $im->filledRectangle(0,0,$map_width,$map_height,$grey);
        # draw the zone boundaries
        for (my $z=0; $z < $map_width; $z += 250) {
            $im->line($z,0,$z,$map_height,$white);
            $im->line(0,$z,$map_width,$z,$white);
        }

        my $chunk_x = ($map_max_x - $map_min_x) / $chunks;
        my $chunk_y = ($map_max_y - $map_min_y) / $chunks;
        
        CHUNK:
        for (my $p=0; $p<$chunks; $p++) {
            for (my $q=0; $q<$chunks; $q++) {
                # Calculate the TLE unit co-ordinates of this chunk.
                my $x_chunk_min = $p * $chunk_x;
                my $x_chunk_max = int($x_chunk_min + $chunk_x);
                $x_chunk_min    = int($x_chunk_min);
    
                my $y_chunk_min = $q * $chunk_y;
                my $y_chunk_max = int($y_chunk_min + $chunk_y);
                $y_chunk_min    = int($y_chunk_min);

                for (my $i=0; $i < $ores->{$p}{$q}{$ore}; $i++) {
                    my $x = randint($x_chunk_min, $x_chunk_max);
                    my $y = randint($y_chunk_min, $y_chunk_max);
                    $im->filledEllipse($x, $y, 20, 20, $ore_colour);
                }
            }
        }

        open(my $fh, '>',  "../../var/starmaps/${ore}_map.png") || die "Cannot create ore image file $!";
        binmode $fh;
        print $fh $im->png;
        close $fh;
    }
}


# Generate a png file that shows the distribution of stars
# 
sub generate_stars_png() {

    my $im = new GD::Image($map_width,$map_height);
    my $white       = $im->colorAllocate(255,255,255);
    my $grey        = $im->colorAllocate(72,72,72);
    my $black       = $im->colorAllocate(0,0,0);
    my $star_colour = $im->colorAllocate(127,255,212);

    $im->filledRectangle(0,0,$map_width,$map_height,$grey);
    # draw the zone boundaries
    for (my $z=0; $z < $map_width; $z += 250) {
        $im->line($z,0,$z,$map_height,$white);
        $im->line(0,$z,$map_width,$z,$white);
    }
    foreach my $ds (keys %$ds_stars) {
        my ($p,$q)  = split(":", $ds);
        foreach my $s (@{$ds_stars->{$ds}}) {
            my $x = $s->{x} - $map_min_x;
            my $y = $s->{y} - $map_min_y;
            $im->filledEllipse($x, $y, 5.5, 5.5, $star_colour);
        }
    }
    open(my $fh, '>',  '../../var/starmaps/starmap.png') || die "Cannot create star image file $!";
    binmode $fh;
    print $fh $im->png;
    close $fh;
}

