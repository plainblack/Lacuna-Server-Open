use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date random_element);
use Getopt::Long;
use List::MoreUtils qw(uniq);
use Data::Rand;
use Data::Dumper;

$|=1;
our $quiet;
GetOptions(
    'quiet'     => \$quiet,  
);

my $band_width = 50; # 50 ensures that a -1500 - 1500 map will be complete in 60

out('Started');
my $start = time;

out('Loading DB');
our $db     = Lacuna->db;
my $bodies  = $db->resultset('Map::Body');
my $stars   = $db->resultset('Map::Star');
my $empire  = $db->resultset('Empire');
my $db_config  = $db->resultset('Config');
my $config = Lacuna->config;

my @asteroid_types  = qw(A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15 A16 A17 A18 A19 A20 A21 A22 A23 A24 A25 A26);
my @habital_types   = qw(P1 P2 P3 P4 P5 P6 P7 P8 P9 P10 P11 P12 P13 P14 P15 P16 P17 P18 P19 P20 P21 P22 P23 P24 P25 P26 P27 P28 P29 P30 P31 P32 P33 P34 P35 P36 P37 P38 P39 P40);
my @gas_giant_types = qw(G1 G2 G3 G4 G5);

my $revamp_x = $db_config->search({name => 'revamp_x'})->first;
my $x_min = int($config->get('map_size/x')->[0]);
my $x_max = int($config->get('map_size/x')->[1]);

if (not defined $revamp_x) {
    out("Starting at x = $x_min. Good Luck!");

    $revamp_x = $db_config->create({
        name    => 'revamp_x',
        value   => $x_min,
    });
}
my $ribben_from = $revamp_x->value;
my $ribben_to   = $revamp_x->value + $band_width;

my %zone_details;

out("Ribbon is between x=$ribben_from and x=$ribben_to");
my %zone_news_cache;
my $search_criteria = { -and => [
    { x => {'>=' => $ribben_from }},
    { x => {'<'  => $ribben_to }},
    ]};
my $bodies = $bodies->search($search_criteria, { order_by => 'y' });
my $stars = $stars->search($search_criteria, { order_by => 'y' });

if ($revamp_x->value > $x_max) {
    out('All done! You may stop the cron job!');
    exit;
}

out('Destroying probes.');
while (my $star = $stars->next) {
    my $probes = $star->probes;
    while (my $probe = $probes->next) {
        out('Destroying '.$probe->empire->name.'s probe attached to '.$star->name);
        $probe->empire->send_predefined_message(
            tags        => ['Spies','Alert'],
            filename    => 'probe_destroyed.txt',
            params      => [$probe->body->id,
                            $probe->body->name,
                            $star->x,
                            $star->y,
                            $star->name],
        );
        $probe->delete;
    }
}

my $colonies_requiring_update;

my $news_a = '... --- ...';
my $news_b = '- .... .  .-. .. -... -... --- -.  .. ...  .... . .-. .';
my $news_c = '.-- .... .- -   .... .- ...- .   .-- .   -.. --- -. . ..--.. ';
my $news_1 = "ALERT: From Deep Space Monitoring Station %d, co-ordinates %d|%d";
my $news_2 = "Automatic sensors detect a cosmic string with energy readings of %d Ancrons.";
my $news_3 = "Cosmic String leaving vast areas of destruction in it's wake.";
my $news_4 = "Deep Space Monitoring station %d, co-ordinates %d|%d shutting down due to sensor overload.";

my $cache = Lacuna->cache;

while (my $body = $bodies->next) {
    # I know it is inefficient to calculate this for every body, but we are only doing it once!
    my $zone = $body->zone;
    determine_zone_details($zone);

    unless ($zone_news_cache{$zone}) {
        unless ($cache->get('revamp_news', $zone)) {
            # we can only 'add_news' to an occupied planet
            if ($body->empire_id) {
                # This ensures that each time a zone receives a news item, it is 'corrupted' differently
                my $seed = $body->x*10000+$body->y;
                srand($seed);

                out("About to add news item");
                $body->add_news(100, $news_a);
                $body->add_news(100, $news_b);
                $body->add_news(100, corrupt_string(sprintf($news_1, rand(1000), $body->x, $body->y)));
                $body->add_news(100, corrupt_string(sprintf($news_2, rand(10000)+80000)));
                $body->add_news(100, corrupt_string(sprintf($news_3, rand(1000))));
                $body->add_news(100, corrupt_string(sprintf($news_4, rand(1000), $body->x, $body->y)));
                $body->add_news(100, $news_c);
                $cache->set('revamp_news', $zone, 1, 60 * 60 * 24 * 7);
            }
        }
        $zone_news_cache{$zone} = 1;
    }

    if ($body->empire_id > 1) {
       wreck_planet($body);
    }
    elsif ($body->get_type eq 'space station') {
        #skip it
    }
    else {
        # are there any mining platforms on this body?
        my $platforms = $db->resultset('MiningPlatforms')->search({
            asteroid_id => $body->id,
        });
        while (my $platform = $platforms->next) {
            $colonies_requiring_update->{$platform->planet_id} = 1;
        }

        convert_body($body);
    }
}

out('Recalculating for affected mining platforms');

# Recalculate all bodies that have mining platforms in the affected strip
for my $body_id (keys %$colonies_requiring_update) {
    my $body = $db->resultset('Map::Body::Planet')->find($body_id);
    out("Recalculating mining platforms for ".$body->name);

    my $ministry = $body->mining_ministry;
    if ($ministry) {
        $ministry->recalc_ore_production;
        $body->recalc_stats;
    }
}


$revamp_x->value($revamp_x->value + $band_width);
$revamp_x->update;

sub corrupt_string {
    my ($str) = @_;

    # generate an array, the length of the string, with random 'bits'
    # 1 in 5 characters is 'corrupted'
    my $error_bits = rand_data(length($str), [0,0,0,0,1]);
    my $error_char = rand_data(length($str), [0..9,'a'..'z','A'..'Z','$','!','@','^','(','.',',',')']);
    # combine everything to create the corrupt string
    my $out = '';
    while ($str) {
        my $good    = substr $str, 0, 1, '';
        my $bad     = substr $error_char, 0, 1, '';
        my $bit     = substr $error_bits, 0, 1, '';
        $out .= $bit ? $bad : $good;
    }

    out("$out");
    return $out;
}

sub wreck_planet {
    my $body = shift;
    out('Wrecking planet '.$body->name);
    $body->needs_surface_refresh(1);
    foreach my $building (@{$body->building_cache}) {
        if ($building->class eq 'Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator') {
            my $now = DateTime->now;
            $building->class('Lacuna::DB::Result::Building::Permanent::Fissure');
            if ($building->is_working) {
                $building->is_working(0);
                $building->work_ends($now);
            }
            $building->is_upgrading(0);
            $building->efficiency(100);
        }
        else {
            $building->spend_efficiency(randint(1,25));
        }
        $building->update;
    }
}

sub convert_body {
    my $body = shift;
    srand($body->id);

    my $type = $body->get_type;
    my $class_prefix = 'Lacuna::DB::Result::Map::Body::';
    if ($type eq 'gas giant') {
        $class_prefix .= 'Planet::GasGiant::';
    }
    elsif ($type eq 'asteroid') {
        $class_prefix .= 'Asteroid::';
    }
    else {
        $class_prefix .= 'Planet::';
    }
    my $details = $zone_details{$type};

    $body->size(randint($details->{min_size}, $details->{max_size}));

    my $t = random_element($details->{types});
    $body->class("$class_prefix$t");
    out("Converting ".$body->name." to $class_prefix$t");
    $body->update;
}

sub determine_zone_details {
    my ($zone) = @_;

    my ($x,$y) = $zone =~ m/(-?\d+)\|(-?\d+)/;
    # seed the random number generator so it starts at the same point for every zone
    my $seed = $x*10000+$y;
    srand($seed);
    out("determining zone details for $zone seed $seed");

    # asteroids
    my %asteroid;
    $asteroid{min_size} = randint(1,6);
    $asteroid{max_size} = $asteroid{min_size} + 6;
    push @{$asteroid{types}}, element_rarity(\@asteroid_types, 1, 1); # rare
    push @{$asteroid{types}}, element_rarity(\@asteroid_types, 2, 3); # uncommon
    push @{$asteroid{types}}, element_rarity(\@asteroid_types, 4, 6); # common

    # habitals
    my %habital;
    $habital{min_size} = randint(30,50);
    $habital{max_size} = $habital{min_size} + 20;
    push @{$habital{types}}, element_rarity(\@habital_types, 1, 1); # rare
    push @{$habital{types}}, element_rarity(\@habital_types, 2, 3); # uncommon
    push @{$habital{types}}, element_rarity(\@habital_types, 6, 6); # common

    # gas giants
    my %gas_giant;
    $gas_giant{min_size} = randint(80,100);
    $gas_giant{max_size} = $gas_giant{min_size} + 21;
    push @{$gas_giant{types}}, element_rarity(\@gas_giant_types, 1, 1); # rare
    push @{$gas_giant{types}}, element_rarity(\@gas_giant_types, 1, 3); # uncommon
    push @{$gas_giant{types}}, element_rarity(\@gas_giant_types, 1, 6); # common

    %zone_details = (
        'asteroid'          => \%asteroid,
        'habitable planet'  => \%habital,
        'gas giant'         => \%gas_giant,
    );
}

sub element_rarity {
    my ($list, $quantity, $rarity) = @_;
    my @elements;
    for (1..$quantity) {
        my $element = random_element($list);
        for (1..$rarity) {
            push @elements, $element;
        }
    }
    return @elements;
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############


sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


