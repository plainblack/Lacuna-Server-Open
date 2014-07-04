use strict;
use 5.010;
use lib '/data/Lacuna-Server/lib';

use GD;

use Lacuna;
use Math::Round;

my $img_file        = '/data/Lacuna-Server/var/www/public/influencemap/today/';
my $img;

my $alliance_ref;

# Pre-defined alliance colours.
# Anything not defined here will be given one of 50 shades of grey
#
my $alliance_rgb = {
    690     => [253, 201, 76],   # S.M.A.
    385     => [149, 76, 253],   # Purple Stars of Avalon
    898     => [76, 253, 98],    # UNSC
    1183    => [253, 76, 105],   # Da Posse
    26      => [253, 83, 76],    # Culture
    7       => [209, 253, 76],   # The Understanding
    524     => [245, 76, 253],   # UPSSU
    978     => [76, 253, 194],   # Anarchy!
    857     => [253, 142, 76],   # The Rebirth
    51      => [90, 76, 253],    # Bad Wolf
    116     => [113, 253, 76],   # Phoenix and the Dragon
    584     => [253, 76, 165],   # Knights who say NI
    1165    => [76, 216, 253],   # Arboretum
    1448    => [253, 238, 76],   # Mercury Confederation
    811     => [186, 76, 253],   # Quos Quies
    1312    => [76, 253, 134],   # Haruchai
    1383    => [76, 157, 253],   # Galactic Republic
    1506    => [76, 120, 253],   # SRA
    1347    => [172, 253, 76],   # Trade Alliance Legion
    1033    => [253, 76, 224],   # Passionate Polluters
    1519    => [76, 253, 230],   # Evil Guard
    34      => [253, 179, 76],   # Les Enfants Sauvages
    1284    => [127, 76, 253],   # Galactic Star Defense
    1157    => [76, 253, 76],    # AoM
    1258    => [253, 76, 128],   # Adv. Terra Cohortis
    1306    => [76, 180, 253],   # N.F.R.
    1127    => [231, 253, 76],   # TLE Admin Team
    376     => [223, 76, 253],   # Flatulent Kittens
    768     => [76, 253, 171],   # Akkadian Templar
    1500    => [253, 119, 76],   # AJLS
    1419    => [80, 80, 80],     # Undead Legions
    211     => [81, 81, 81],     # The Lazorblade Consortium
    1501    => [82, 82, 82],     # Efrosian Confederacy
    630     => [83, 83, 83],     # Five Napkin Burger
    1252    => [84, 84, 84],     # DelganHold
    1355    => [85, 85, 85],     # Plan Z
    1350    => [86, 86, 86],     # Order of the Void
    883     => [87, 87, 87],     # Northern Trade Union
};

# generate a list of colors
my $GOLDEN_RATIO_CONJUGATE = 0.618033988749895;
my $h = 0.5;

# We can generate new colors, by extending past 30 below.
my @colors = ();
my $index = 0;
foreach (1..30) {
    my ($r, $g, $b) = get_rgb();
    push @colors, [$r, $g, $b];
    $index++;
}
# the next colour grey to use for Alliances which we don't have
# a pre-defined colour for
my $grey = 88;


foreach my $alliance_id (690,385,898,1183,26,7,524,978,857,51,116,584,1165,1448,811,1312,1383,1506,1347,1033,1519,34,1284,1157,1258,1306,1127,376,768,1500,1419,211,1501,630,1252,1355,1350,883) {

    print("<img src='ally_$alliance_id.png' width='1500' height='1500' class='overlay' style='z-index: $alliance_id' />\n");

    $img             = GD::Image->newTrueColor(1500,1500);
    my $clr_background  = $img->colorAllocateAlpha(0,0,0,127);

    $img->alphaBlending(0);
    $img->saveAlpha(1);
    $img->filledRectangle(0,0,1499,1499,$clr_background);

    # Get all stars seized by this alliance
    my $stars_rs = Lacuna->db->resultset('Map::Star')->search({
        alliance_id => $alliance_id,
        influence   => {'>' => 0},
    });
    while (my $star = $stars_rs->next) {
#        print("Star: ".$star->name."\n");
        my $x   = $star->x;
        my $y   = $star->y;

        my $alpha = 127 - ($star->influence / 4);
        $alpha = 0   if $alpha < 0;
        $alpha = 127 if $alpha > 127;

        my ($r, $g, $b) = @{$alliance_rgb->{$alliance_id}};
        my $clr = $img->colorAllocateAlpha($r, $g, $b, $alpha);

        # Ignore starter and neutral zones
        if ($star->zone ne "-3|0" and $star->zone ne "-1|1" and $star->zone ne "-1|-1" and $star->zone ne "1|1" and $star->zone ne "1|-1") {
            draw_influence($x, $y, $clr);
        }
    }
#    print("Saving image file ally_$alliance_id\n");
    my $png_data = $img->png;
    open (FILE, ">${img_file}ally_${alliance_id}.png") || die;
    binmode(FILE);
    print FILE $png_data;
    close FILE;
}

sub draw_influence {
    my ($x, $y, $clr) = @_;

    $x = nearest(1, $x / 2);
    $y = nearest(1, $y / 2);

    $img->filledEllipse(750+$x, 750-$y, 6, 6, $clr);
}

sub get_rgb {
    $h += $GOLDEN_RATIO_CONJUGATE;
    $h = $h - int($h);
    return hsv_to_rgb($h, 0.7, 0.99);
}

# HSV values in [0..1]
# (Hue, Saturation, Value)
# returns [r, g, b] values from 0 to 255
sub hsv_to_rgb {
    my ($h, $s, $v) = @_;

    my $hi  = int($h*6);
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
    return(int($r * 256), int($g * 256), int($b * 256));
}
1;

