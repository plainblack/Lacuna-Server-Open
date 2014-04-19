use strict;
use 5.010;
use lib 'lib';

use GD;

use Lacuna::DB;
use Lacuna;

my $img_file        = '/data/Lacuna-Server/var/www/public/alliancemap/today.png';
my $img             = GD::Image->new(3500,3000);
my $clr_background  = $img->colorAllocate(0,0,0);
my $clr_grid        = $img->colorAllocate(75,75,75);
my $clr_star        = $img->colorAllocate(50,50,50);
my $clr_red         = $img->colorAllocate(255,0,0);

my $alliance_ref;
my $alliance_color;

# Pre-defined alliance colours.
# Anything not defined here will be given an arbitrary shade of grey
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
#    print "$index\t$r\t$g\t$b\n";
    $index++;
}
# the next colour grey to use for Alliances which we don't have
# a pre-defined colour for
my $grey = 88;

$img->filledRectangle(0,0,3499,2999,$clr_background);
# draw the grid

GRID: foreach my $i (0..12) {
    next GRID if $i == 6;
    my $offset = $i * 250;
    $img->filledRectangle($offset,0,$offset+2,2999,$clr_grid);
    $img->filledRectangle(0,$offset,2999,$offset+2,$clr_grid);
}

my $db = Lacuna->db;
my $stars_rs = $db->resultset('Map::Star')->search({}, {
    prefetch => {station => 'alliance'},
});

print "processing star data\n";
while (my $star = $stars_rs->next) {
    print($star->id."\tProcessing star ".$star->name."\n");

    my $x   = $star->x;
    my $y   = $star->y;
    my $clr = $clr_star;

    my $alliance_id = $star->alliance_id;
    my $star_size = 1;

    if ($alliance_id and $star->seize_strength > 0) {
        if (not $alliance_ref->{$alliance_id}) {
            my ($alliance) = $db->resultset('Alliance')->search({id => $alliance_id});
            my ($r, $g, $b);
            if ($alliance_rgb->{$alliance->id}) {
                ($r, $g, $b) = @{$alliance_rgb->{$alliance->id}};
            }
            else {
                ($r, $g, $b) = ($grey, $grey, $grey);
                $grey++;
            }
            $alliance_ref->{$alliance->id} = $alliance;
            $alliance_color->{$alliance->id} = $img->colorAllocate($r, $g, $b);
        }
        $clr = $alliance_color->{$alliance_id};
        if ($star->seize_strength > 200) {
            $star_size = 4;
        }
        elsif ($star->seize_strength > 100) {
            $star_size = 3;
        }
        elsif ($star->seize_strength > 50) {
            $star_size = 2;
        }
    }
    if ($star->zone eq "-3|0" || $star->zone eq "-1|1" || $star->zone eq "-1|-1" || $star->zone eq "1|1" || $star->zone eq "1|-1") {
        # neutral and starter zones 
        $clr = $clr_star;
        $star_size = 2;
    }
    draw_star($x, $y, $clr, $star_size);            
}

# output the image
my $png_data = $img->png;
open (FILE, ">$img_file") || die;
binmode(FILE);
print FILE $png_data;
close FILE;

sub draw_star {
    my ($x, $y, $color, $size) = @_;

    print "Draw star color [$color]\n";
    # Drawe base star.
    if ($size == 1 ) {
        draw_star_1($x, $y, $clr_star);
        $img->setPixel(1500+$x,1500-$y,$color);
        $img->setPixel(1500+$x,1501-$y,$color);
        $img->setPixel(1501+$x,1500-$y,$color);
        $img->setPixel(1501+$x,1501-$y,$color);

    }
    elsif ($size == 2) {
        draw_star_1($x, $y, $color);
    }
    elsif ($size == 3) {
        draw_star_2($x, $y, $color, 6.5);
    }
    else {
        draw_star_2($x, $y, $color, 13);
    }
}

sub draw_star_1 {
    my ($x, $y, $color) = @_;

    print "Draw star color $color\n";
    foreach my $v (0..3) {
        foreach my $w (0..3) {
            if ($v==1 or $v==2 or $w==1 or $w==2) {
                my $px = $x+1500-1+$v;
                my $py = 3000 - ($y+1500-1+$w);
                $img->setPixel($px,$py,$color);
            }
        }
    }
}

sub draw_star_2 {
    my ($x, $y, $color, $radius) = @_;

    $img->filledEllipse(1500+$x,1500-$y,$radius,$radius,$color);
}


# use golden ratio

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

